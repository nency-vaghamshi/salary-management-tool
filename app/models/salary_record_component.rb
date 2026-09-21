class SalaryRecordComponent < ApplicationRecord
  belongs_to :salary_record
  belongs_to :salary_component

  before_validation :snapshot_calculation_type_from_component

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :salary_component_id, uniqueness: { scope: :salary_record_id }

  private

  def snapshot_calculation_type_from_component
    self.calculation_type ||= salary_component&.calculation_type
  end
end
