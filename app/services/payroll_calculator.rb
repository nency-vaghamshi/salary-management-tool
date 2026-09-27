class PayrollCalculator
  Result = Struct.new(:payroll_run, :processed_count, :skipped, keyword_init: true)
  BATCH_SIZE = 1000

  def initialize(payroll_run)
    @payroll_run = payroll_run
  end

  def call
    raise ArgumentError, "Only a draft payroll run can be processed" unless payroll_run.draft?
    # Committed outside the transaction so the run page can show "processing"
    # while the (long) calculation is in flight.
    payroll_run.update!(status: "processing")
    processed = 0
    skipped = []
    line_items_buffer = []

    # All line items and the "completed" flip commit together: a crash midway
    # rolls back every inserted batch, so a failed run never has partial items.
    PayrollRun.transaction do
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
    end

    Result.new(payroll_run: payroll_run, processed_count: processed, skipped: skipped)
  rescue StandardError => e
    payroll_run.update!(status: "failed")
    raise e
  end

  private

  attr_reader :payroll_run

  def eligible_employees
    Employee
      .joins(:employments)
      .where(employments: { status: "active" })
      .includes(
        employments: [
          { payroll_country: { tax_configurations: :tax_brackets } },
          { salary_records: [ :currency, { salary_record_components: :salary_component } ] }
        ]
      ).distinct
  end

  def process_employee(employee)
    # Read from the preloaded employments tree; employee.salary_records (a
    # has_many :through) is not preloaded and would query once per employee.
    employment = employee.employments.find(&:active?)
    salary_record = employment&.salary_records&.find(&:active?)

    return skip(employee, "No active employment") unless employment
    return skip(employee, "No salary record") unless salary_record

    estimate = SalaryTaxEstimator.new(salary_record).call
    return skip(employee, estimate.error) if estimate.error

    # Tax is computed on the full annual income (progressive brackets), then
    # the run pays only its period's share of both net pay and tax.
    # Return a raw hash of attributes instead of saving immediately
    {
      line_item: {
        payroll_run_id: payroll_run.id,
        employee_id: employee.id,
        salary_record_id: salary_record.id,
        amount: (estimate.net_amount * proration_factor).round(2),
        tax_amount: (estimate.tax_amount * proration_factor).round(2),
        created_at: Time.current,
        updated_at: Time.current
      }
    }
  rescue StandardError => e
    skip(employee, e.message)
  end

  def proration_factor
    @proration_factor ||= payroll_run.proration_factor
  end

  # Uses Rails insert_all! to write 1000 rows in exactly ONE SQL query
  def bulk_insert_line_items(items)
    PayrollLineItem.insert_all!(items)
  end

  def skip(employee, reason)
    { skipped: { employee_id: employee.id, employee_name: employee.full_name, reason: reason } }
  end
end
