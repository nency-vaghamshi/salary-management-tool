class PayrollCalculator
  Result = Struct.new(:payroll_run, :processed_count, :skipped, keyword_init: true)
  BATCH_SIZE = 1000

  def initialize(payroll_run)
    @payroll_run = payroll_run
  end

  def call
    raise ArgumentError, "Only a draft payroll run can be processed" unless payroll_run.draft?
    payroll_run.update!(status: "processing")
    processed = 0
    skipped = []
    line_items_buffer = []

    eligible_employees.find_each(batch_size: BATCH_SIZE) do |employee|
      outcome = process_employee(employee)
      if outcome[:skipped]
        skipped << outcome[:skipped]
      else
        processed += 1
        line_items_buffer << outcome[:line_item]

        # Flush buffer to database in bulk chunks
        if line_items_buffer.size >= BATCH_SIZE
          bulk_insert_line_items(line_items_buffer)
          line_items_buffer.clear
        end
      end
    end

    # Insert any remaining records left in the buffer
    bulk_insert_line_items(line_items_buffer) if line_items_buffer.any?

    payroll_run.update!(status: "completed", processed_at: Time.current, skipped_employees: skipped)
    Result.new(payroll_run: payroll_run, processed_count: processed, skipped: skipped)
  rescue StandardError => e
    payroll_run.update!(status: "failed")
    raise e
  end

  private

  attr_reader :payroll_run

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

    # Return a raw hash of attributes instead of saving immediately
    {
      line_item: {
        payroll_run_id: payroll_run.id,
        employee_id: employee.id,
        salary_record_id: salary_record.id,
        amount: estimate.net_amount,
        tax_amount: estimate.tax_amount,
        created_at: Time.current,
        updated_at: Time.current
      }
    }
  rescue StandardError => e
    skip(employee, e.message)
  end

  # Uses Rails insert_all! to write 1000 rows in exactly ONE SQL query
  def bulk_insert_line_items(items)
    PayrollLineItem.insert_all!(items)
  end

  def skip(employee, reason)
    { skipped: { employee_id: employee.id, employee_name: employee.full_name, reason: reason } }
  end
end
