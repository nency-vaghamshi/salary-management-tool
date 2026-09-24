# Issues one Payslip per line item of a completed payroll run. Bulk inserts
# in batches (a run can have ~10k line items) and is idempotent: the unique
# index on payroll_line_item_id makes re-running skip slips already issued.
#
# A payslip is a record of issue; its figures are read from the frozen line
# item, so it always shows exactly what the run paid.
class PayslipGenerator
  BATCH_SIZE = 1000

  def initialize(payroll_run)
    @payroll_run = payroll_run
  end

  def call
    raise ArgumentError, "Payslips can only be issued for a completed run" unless payroll_run.completed?

    issued = 0
    payroll_run.payroll_line_items.where.missing(:payslip).in_batches(of: BATCH_SIZE) do |batch|
      now = Time.current
      rows = batch.pluck(:id).map { |line_item_id| { payroll_line_item_id: line_item_id, generated_at: now, created_at: now, updated_at: now } }
      issued += Payslip.insert_all(rows, unique_by: :payroll_line_item_id).length
    end
    issued
  end

  private

  attr_reader :payroll_run
end
