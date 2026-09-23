class Payslip < ApplicationRecord
  belongs_to :payroll_line_item

  validates :payroll_line_item_id, uniqueness: true
end
