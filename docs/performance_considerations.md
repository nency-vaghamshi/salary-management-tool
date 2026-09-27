# Performance Considerations

Payroll runs process every employee (~10k), so the pipeline is built to keep
query count and memory flat as headcount grows.

Measured on 10,000 employees: **~8s**

## Background job takes an id, not a record

`ProcessPayrollRunJob.perform_later(payroll_run.id)`

- Keeps job arguments tiny and makes the worker read the run's current state.
- `PayrollRun.find_by(id:)` turns a run deleted before execution into a no-op
  instead of a failure.

## Filter in the database, preload the rest

`PayrollCalculator#eligible_employees` joins `employments` with
`status = 'active'` and uses `.distinct`, so inactive employees are never loaded
into Ruby. The whole tree the calculation needs (employments, salary records,
components, country tax brackets) is preloaded in one pass.

Inside the loop, lookups read that preloaded data:

```ruby
employment    = employee.employments.find(&:active?)
salary_record = employment&.salary_records&.find(&:active?)
```

## Batched reads and writes

- `find_each(batch_size: 1000)` keeps memory bounded.
- Line items are buffered and written with `insert_all!`, so 10k rows take ~10
  `INSERT`s instead of 10k.

## Salary ledger immutability (database triggers)

`BEFORE UPDATE` triggers on `salary_records` and `salary_record_components` enforce the immutable ledger in Postgres.
Defined in one migration via the `fx` gem, which keeps them in `schema.rb`
