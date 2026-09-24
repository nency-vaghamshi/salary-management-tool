# Creates the next salary record for an employment. Per the immutable-ledger
# design, a "salary change" never overwrites history: it closes whatever
# record is currently open-ended (effective_to = the day before the new
# record starts, status flipped to inactive) and opens a new active one in
# its place, atomically.
#
# Also accepts a new, unsaved employment (an employee's first salary): it is
# saved in the same transaction, so a rejected salary never leaves an
# orphaned employment behind.
class SalaryRevisionService
  Result = Struct.new(:success?, :salary_record, :errors)

  def initialize(employment:, currency:, effective_from:, component_amounts:)
    @employment = employment
    @currency = currency
    @effective_from = parse_date(effective_from)
    @component_amounts = component_amounts
  end

  def call
    return Result.new(false, nil, [ "At least one salary component is required" ]) if component_amounts.blank?
    return Result.new(false, nil, [ "Effective from is not a valid date" ]) unless effective_from

    salary_record = nil

    ActiveRecord::Base.transaction do
      employment.save! if employment.new_record?
      close_current_record!
      salary_record = create_salary_record!
      create_components!(salary_record)
    end

    Result.new(true, salary_record, [])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(false, nil, e.record.errors.full_messages)
  end

  private

  attr_reader :employment, :currency, :effective_from, :component_amounts

  def parse_date(value)
    return value if value.is_a?(Date)

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def close_current_record!
    current_record = employment.salary_records.find_by(effective_to: nil)
    return unless current_record

    current_record.update!(effective_to: effective_from - 1.day, status: "inactive")
  end

  def create_salary_record!
    employment.salary_records.create!(
      currency: currency,
      effective_from: effective_from,
      status: "active"
    )
  end

  def create_components!(salary_record)
    component_amounts.each do |salary_component, amount|
      salary_record.salary_record_components.create!(
        salary_component: salary_component,
        amount: amount,
        calculation_type: salary_component.calculation_type
      )
    end
  end
end
