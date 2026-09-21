class Payslip < ApplicationRecord
  belongs_to :payroll_run
  belongs_to :employee

  enum :status, { generated: "generated", issued: "issued", void: "void" }

  validates :payslip_number, presence: true, uniqueness: true
  validates :employee_id, uniqueness: { scope: :payroll_run_id }
end
