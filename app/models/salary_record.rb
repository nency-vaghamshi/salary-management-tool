class SalaryRecord < ApplicationRecord
  include Auditable

  belongs_to :employment
  belongs_to :currency

  has_many :salary_record_components, dependent: :destroy
  has_many :salary_components, through: :salary_record_components
  has_many :payroll_line_items, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }

  validates :effective_from, presence: true
  validate :effective_to_on_or_after_effective_from
  validate :period_does_not_overlap_existing_records
  validate :only_one_open_ended_record_per_employment

  # Component amounts are stored pre-resolved (calculation_type records how
  # each was derived, for audit purposes), so the total is a plain sum.
  def total_amount
    salary_record_components.sum(&:amount)
  end

  private

  def effective_to_on_or_after_effective_from
    return if effective_to.blank? || effective_from.blank?
    return if effective_to >= effective_from

    errors.add(:effective_to, "must be on or after the effective_from date")
  end

  def period_does_not_overlap_existing_records
    return if effective_from.blank? || employment_id.blank?

    new_effective_to = effective_to || Date::Infinity.new

    overlaps = other_records_for_employment.any? do |other|
      other_effective_to = other.effective_to || Date::Infinity.new

      effective_from <= other_effective_to && other.effective_from <= new_effective_to
    end

    return unless overlaps

    errors.add(:effective_from, "overlaps an existing salary record for this employment")
  end

  def only_one_open_ended_record_per_employment
    return unless effective_to.nil?
    return if employment_id.blank?

    return unless other_records_for_employment.where(effective_to: nil).exists?

    errors.add(:effective_to, "only one open-ended salary record is allowed per employment")
  end

  def other_records_for_employment
    scope = SalaryRecord.where(employment_id: employment_id)
    scope = scope.where.not(id: id) if persisted?
    scope
  end
end
