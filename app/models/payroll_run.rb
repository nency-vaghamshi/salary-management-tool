class PayrollRun < ApplicationRecord
  has_many :payroll_line_items, dependent: :destroy
  has_many :payslips, through: :payroll_line_items

  enum :status, { draft: "draft", processing: "processing", completed: "completed", failed: "failed" }

  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :period_start, uniqueness: { scope: :period_end, message: "has already been taken for this period" }
  validate :period_end_on_or_after_period_start

  private

  def period_end_on_or_after_period_start
    return if period_start.blank? || period_end.blank?
    return if period_end >= period_start

    errors.add(:period_end, "must be on or after the period_start date")
  end
end
