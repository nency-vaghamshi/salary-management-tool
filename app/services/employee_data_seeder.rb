# Seeds payroll-ready employees: each one gets an active employment and an
# open-ended salary record with components, so the dataset can go straight
# through a payroll run.
#
# Built for volume (10k+ rows), so it writes with insert_all! instead of
# ActiveRecord models: ~4 INSERTs per 1,000 employees rather than ~5 round
# trips per employee. That intentionally skips callbacks, so no AuditLog rows
# are written; seed data isn't an HR action.
#
# All randomness goes through Faker (ids are picked with Faker::Base.sample),
# so setting Faker::Config.random makes a run repeatable.
#
# Measured: 10k employees (+ 10k employments, 10k salary records, 30k
# components) in ~8s, vs ~150s extrapolated for per-record create!.
class EmployeeDataSeeder
  BATCH_SIZE = 1_000
  EMAIL_DOMAIN = "acme.test".freeze
  EMPLOYEE_NUMBER_FORMAT = "EMP-%05d".freeze
  HIRED_WITHIN_DAYS = 5 * 365

  # Annual amounts. Only BASE is required; other components are included
  # when they exist, so seeding still works with a smaller catalog.
  ANNUAL_AMOUNT_RANGES = {
    "BASE" => 30_000..150_000,
    "HOUSING" => 0..24_000,
    "TRANSPORT" => 0..6_000
  }.freeze

  class MissingReferenceDataError < StandardError; end

  def self.call(count)
    new(count).call
  end

  def initialize(count)
    raise ArgumentError, "count must be a non-negative integer" unless count.is_a?(Integer) && count >= 0

    @count = count
  end

  # Returns the number of employees created.
  def call
    return 0 if count.zero?

    load_reference_data!
    first_number = next_employee_number

    (first_number...(first_number + count)).each_slice(BATCH_SIZE) do |employee_numbers|
      # One transaction per batch: a failure never leaves an employee without
      # its employment or salary, and memory stays flat regardless of count.
      ActiveRecord::Base.transaction { seed_batch(employee_numbers) }
    end

    count
  end

  private

  attr_reader :count, :department_ids, :job_title_ids, :nationality_country_ids,
              :currency_id_by_payroll_country_id, :salary_components

  # ---------------------------------------------------------------------------
  # Reference data: loaded once per run so row building never hits the DB.
  # ---------------------------------------------------------------------------

  def load_reference_data!
    @department_ids = Department.ids
    @job_title_ids = JobTitle.ids
    @nationality_country_ids = Country.ids
    # Only countries with a tax configuration can be paid through payroll,
    # so payroll countries are drawn from those alone.
    @currency_id_by_payroll_country_id = Country.where(id: TaxConfiguration.select(:country_id))
                                                .pluck(:id, :currency_id).to_h
    @salary_components = SalaryComponent.active.where(code: ANNUAL_AMOUNT_RANGES.keys).to_a

    validate_reference_data!
  end

  def validate_reference_data!
    missing = []
    missing << "departments" if department_ids.empty?
    missing << "job titles" if job_title_ids.empty?
    missing << "countries with a tax configuration" if currency_id_by_payroll_country_id.empty?
    missing << "BASE salary component" if salary_components.none? { |component| component.code == "BASE" }
    return if missing.empty?

    raise MissingReferenceDataError, "Cannot seed employees, missing: #{missing.join(', ')}"
  end

  # Employee numbers are free text for HR, so only ones in the seeder's own
  # EMP-<digits> format count. Compared numerically: as strings, "EMP-9999"
  # sorts after "EMP-10000".
  def next_employee_number
    Employee.pick(Arel.sql("MAX(SUBSTRING(employee_number FROM '^EMP-([0-9]+)$')::integer)")).to_i + 1
  end

  # ---------------------------------------------------------------------------
  # Persistence: one bulk insert per table per batch.
  # ---------------------------------------------------------------------------

  # Each step RETURNs the columns the next step needs alongside the id, so
  # parent/child rows are paired without relying on Postgres returning rows
  # in insertion order.
  def seed_batch(employee_numbers)
    timestamp = Time.current

    employees = Employee.insert_all!(
      employee_numbers.map { |number| employee_row(number, timestamp) },
      returning: %w[id residence_country_id]
    )

    employments = Employment.insert_all!(
      employees.rows.map do |employee_id, residence_country_id|
        employment_row(employee_id, residence_country_id, timestamp)
      end,
      returning: %w[id payroll_country_id start_date]
    )

    salary_records = SalaryRecord.insert_all!(
      employments.rows.map do |employment_id, payroll_country_id, start_date|
        salary_record_row(employment_id, payroll_country_id, start_date, timestamp)
      end,
      returning: %w[id]
    )

    SalaryRecordComponent.insert_all!(
      salary_records.rows.flat_map { |(salary_record_id)| salary_component_rows(salary_record_id, timestamp) }
    )
  end

  # ---------------------------------------------------------------------------
  # Row builders: Faker-generated attributes, no DB access.
  # ---------------------------------------------------------------------------

  def employee_row(number, timestamp)
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name

    {
      employee_number: format(EMPLOYEE_NUMBER_FORMAT, number),
      first_name: first_name,
      last_name: last_name,
      email: email_for(first_name, last_name, number),
      department_id: Faker::Base.sample(department_ids),
      job_title_id: Faker::Base.sample(job_title_ids),
      nationality_country_id: Faker::Base.sample(nationality_country_ids),
      residence_country_id: Faker::Base.sample(currency_id_by_payroll_country_id.keys),
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  # Employees are paid where they live, which keeps the seeded data
  # consistent with the tax rules a payroll run applies.
  def employment_row(employee_id, residence_country_id, timestamp)
    {
      employee_id: employee_id,
      payroll_country_id: residence_country_id,
      start_date: Faker::Date.backward(days: HIRED_WITHIN_DAYS),
      status: "active",
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def salary_record_row(employment_id, payroll_country_id, start_date, timestamp)
    {
      employment_id: employment_id,
      currency_id: currency_id_by_payroll_country_id.fetch(payroll_country_id),
      effective_from: start_date,
      status: "active",
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def salary_component_rows(salary_record_id, timestamp)
    salary_components.map do |component|
      range = ANNUAL_AMOUNT_RANGES.fetch(component.code)

      {
        salary_record_id: salary_record_id,
        salary_component_id: component.id,
        amount: Faker::Number.between(from: range.min, to: range.max),
        calculation_type: component.calculation_type,
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  end

  # Faker's email helpers shuffle name parts and keep accents/apostrophes;
  # this gives a stable "first.last.number" address instead. Embedding the
  # employee number makes it unique by construction, so there's no need for
  # Faker's unique generator (which slows down and runs out of names before 10k).
  def email_for(first_name, last_name, number)
    local_part = "#{first_name} #{last_name}".parameterize(separator: ".")
    "#{local_part}.#{number}@#{EMAIL_DOMAIN}"
  end
end
