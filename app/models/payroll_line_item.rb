class PayrollLineItem < ApplicationRecord
  belongs_to :payroll_run
  belongs_to :employee
  belongs_to :salary_record

  has_one :payslip, dependent: :destroy

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: :payroll_run_id, message: "already has a line item for this payroll run" }
end
