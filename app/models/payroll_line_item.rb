class PayrollLineItem < ApplicationRecord
  belongs_to :payroll_run
  belongs_to :employee
  belongs_to :salary_record
  belongs_to :salary_component

  before_validation :snapshot_component_type_from_component

  enum :component_type, { earning: "earning", deduction: "deduction" }

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  private

  def snapshot_component_type_from_component
    self.component_type ||= salary_component&.component_type
  end
end
