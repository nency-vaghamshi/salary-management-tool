class Payslip < ApplicationRecord
  belongs_to :payroll_line_item
  has_one :payroll_run, through: :payroll_line_item
  has_one :employee, through: :payroll_line_item

  validates :payroll_line_item_id, uniqueness: true

  # PS-2026-09-000123: period + line item, stable and unique per slip.
  def reference
    "PS-#{payroll_line_item.payroll_run.period_start.strftime('%Y-%m')}-#{payroll_line_item_id.to_s.rjust(6, '0')}"
  end
end
