require "rails_helper"

RSpec.describe SalaryRecord, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:salary_record)).to be_valid
  end

  it "is invalid without an employment" do
    record = build_stubbed(:salary_record, employment: nil)

    expect(record).not_to be_valid
    expect(record.errors[:employment]).to include("must exist")
  end

  it "is invalid without a currency" do
    record = build_stubbed(:salary_record, currency: nil)

    expect(record).not_to be_valid
    expect(record.errors[:currency]).to include("must exist")
  end

  it "is invalid without an effective_from date" do
    record = build_stubbed(:salary_record, effective_from: nil)

    expect(record).not_to be_valid
    expect(record.errors[:effective_from]).to include("can't be blank")
  end

  it "is valid with a nil effective_to, representing an open-ended record" do
    expect(build_stubbed(:salary_record, effective_to: nil)).to be_valid
  end

  it "is invalid when effective_to is before effective_from" do
    record = build_stubbed(:salary_record, effective_from: Date.new(2025, 4, 1), effective_to: Date.new(2025, 3, 31))

    expect(record).not_to be_valid
    expect(record.errors[:effective_to]).to include("must be on or after the effective_from date")
  end

  it "is invalid when its period overlaps an existing record for the same employment" do
    employment = create(:employment)
    create(:salary_record, employment: employment, effective_from: Date.new(2024, 4, 1), effective_to: Date.new(2025, 3, 31))
    overlapping = build_stubbed(:salary_record, employment: employment, effective_from: Date.new(2024, 6, 1), effective_to: Date.new(2026, 5, 31))

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:effective_from]).to include("overlaps an existing salary record for this employment")
  end

  it "is valid when its period is adjacent to, but does not overlap, an existing record" do
    employment = create(:employment)
    create(:salary_record, employment: employment, effective_from: Date.new(2024, 4, 1), effective_to: Date.new(2025, 3, 31))
    adjacent = build_stubbed(:salary_record, employment: employment, effective_from: Date.new(2025, 4, 1), effective_to: Date.new(2026, 3, 31))

    expect(adjacent).to be_valid
  end

  it "is invalid when the employment already has an open-ended salary record" do
    employment = create(:employment)
    create(:salary_record, employment: employment, effective_from: Date.new(2024, 4, 1), effective_to: nil)
    another_open_ended = build_stubbed(:salary_record, employment: employment, effective_from: Date.new(2025, 4, 1), effective_to: nil)

    expect(another_open_ended).not_to be_valid
    expect(another_open_ended.errors[:effective_to]).to include("only one open-ended salary record is allowed per employment")
  end

  it "does not conflict with a salary record from a different employment" do
    employment = create(:employment)
    create(:salary_record, employment: employment, effective_from: Date.new(2024, 4, 1), effective_to: nil)

    other_employment = create(:employment)
    other_record = build_stubbed(:salary_record, employment: other_employment, effective_from: Date.new(2024, 4, 1), effective_to: nil)

    expect(other_record).to be_valid
  end

  it "has many payroll_line_items" do
    salary_record = create(:salary_record)
    line_item = create(:payroll_line_item, salary_record: salary_record, employee: salary_record.employment.employee)

    expect(salary_record.payroll_line_items).to include(line_item)
  end
end
