class PayrollRun < ApplicationRecord
  has_many :payroll_line_items, dependent: :destroy
  has_many :payslips, through: :payroll_line_items

  enum :status, { draft: "draft", processing: "processing", completed: "completed", failed: "failed" }

  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :period_start, uniqueness: { scope: :period_end, message: "has already been taken for this period" }
  validate :period_end_on_or_after_period_start

  # Inclusive day count, so a 1–30 Sep run covers 30 days.
  def period_days
    (period_end - period_start).to_i + 1
  end

  # Share of the year this run pays. Salaries and tax are stored and
  # calculated annually (progressive brackets need the full-year income), so
  # a run pays annual net/tax x this factor. Uses the year the period starts
  # in; a full calendar month is ~1/12.
  def proration_factor
    days_in_year = Date.leap?(period_start.year) ? 366 : 365
    period_days.to_d / days_in_year
  end

  private

  def period_end_on_or_after_period_start
    return if period_start.blank? || period_end.blank?
    return if period_end >= period_start

    errors.add(:period_end, "must be on or after the period_start date")
  end
end
