class PayrollLineItem < ApplicationRecord
  belongs_to :payroll_run
  belongs_to :employee
  belongs_to :salary_record

  has_one :payslip, dependent: :destroy

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
