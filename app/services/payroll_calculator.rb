# Processes a draft PayrollRun: for every employee with an active employment
# and a current salary record, computes the tax-aware final salary (via
# SalaryTaxEstimator, which resolves tax country from
# employment.payroll_country_id) and persists it as a PayrollLineItem.
#
# Each employee is handled independently rather than inside one giant
# transaction, so one bad or unconfigured-country record doesn't roll back
# everyone else's already-computed payroll.
class PayrollCalculator
  Result = Struct.new(:payroll_run, :processed_count, :skipped, keyword_init: true)

  def initialize(payroll_run)
    @payroll_run = payroll_run
  end

  def call
    raise ArgumentError, "Only a draft payroll run can be processed" unless payroll_run.draft?

    payroll_run.update!(status: "processing")
    processed = 0
    skipped = []

    eligible_employees.find_each do |employee|
      outcome = process_employee(employee)
      outcome[:skipped] ? skipped << outcome[:skipped] : processed += 1
    end

    payroll_run.update!(status: "completed", processed_at: Time.current, skipped_employees: skipped)
    Result.new(payroll_run: payroll_run, processed_count: processed, skipped: skipped)
  rescue StandardError => e
    payroll_run.update!(status: "failed")
    raise e
  end

  private

  attr_reader :payroll_run

  # Plain preloading only (no joins/where on the same association tree) so
  # Rails issues a handful of flat, indexed "WHERE id IN (...)" queries per
  # batch instead of eager_load-ing employments/salary_records/components
  # into one combinatorial join — the latter took 10k employees from a few
  # seconds to nearly 3 minutes. "Active employment" filtering happens in
  # Ruby in process_employee, which needs the current one, not just any.
  def eligible_employees
    Employee.includes(
      employments: [
        { payroll_country: { tax_configurations: :tax_brackets } },
        { salary_records: [ :currency, { salary_record_components: :salary_component } ] }
      ]
    )
  end

  def process_employee(employee)
    employment = employee.current_employment
    salary_record = employee.current_salary_record

    return skip(employee, "No active employment") unless employment&.active?
    return skip(employee, "No salary record") unless salary_record

    estimate = SalaryTaxEstimator.new(salary_record).call
    return skip(employee, estimate.error) if estimate.error

    PayrollLineItem.create!(
      payroll_run: payroll_run,
      employee: employee,
      salary_record: salary_record,
      amount: estimate.net_amount,
      tax_amount: estimate.tax_amount
    )

    {}
  rescue StandardError => e
    skip(employee, e.message)
  end

  def skip(employee, reason)
    { skipped: { employee_id: employee.id, employee_name: employee.full_name, reason: reason } }
  end
end
