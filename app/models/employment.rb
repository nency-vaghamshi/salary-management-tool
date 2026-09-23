class Employment < ApplicationRecord
  belongs_to :employee
  belongs_to :payroll_country, class_name: "Country"

  has_many :salary_records, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive", terminated: "terminated" }

  validates :start_date, presence: true
  validate :end_date_on_or_after_start_date

  private

  def end_date_on_or_after_start_date
    return if end_date.blank? || start_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be on or after the start_date date")
  end
end
