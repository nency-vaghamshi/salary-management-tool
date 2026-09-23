require "rails_helper"

RSpec.describe Employment, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:employment)).to be_valid
  end

  it "is invalid without an employee" do
    employment = build_stubbed(:employment, employee: nil)

    expect(employment).not_to be_valid
    expect(employment.errors[:employee]).to include("must exist")
  end

  it "is invalid without a payroll_country" do
    employment = build_stubbed(:employment, payroll_country: nil)

    expect(employment).not_to be_valid
    expect(employment.errors[:payroll_country]).to include("must exist")
  end

  it "is invalid without a start_date" do
    employment = build_stubbed(:employment, start_date: nil)

    expect(employment).not_to be_valid
    expect(employment.errors[:start_date]).to include("can't be blank")
  end

  it "is valid with a nil end_date, representing an ongoing employment" do
    expect(build_stubbed(:employment, end_date: nil)).to be_valid
  end

  it "is invalid when end_date is before start_date" do
    employment = build_stubbed(:employment, start_date: Date.new(2025, 4, 1), end_date: Date.new(2025, 3, 31))

    expect(employment).not_to be_valid
    expect(employment.errors[:end_date]).to include("must be on or after the start_date date")
  end

  it "is valid when end_date is on or after start_date" do
    employment = build_stubbed(:employment, start_date: Date.new(2024, 4, 1), end_date: Date.new(2025, 3, 31))

    expect(employment).to be_valid
  end

  it "defaults to the active status" do
    expect(build_stubbed(:employment).status).to eq("active")
  end

  it "rejects a status outside the defined set" do
    expect { build_stubbed(:employment, status: "on_leave") }.to raise_error(ArgumentError)
  end

  it "has many salary_records" do
    employment = create(:employment)
    salary_record = create(:salary_record, employment: employment)

    expect(employment.salary_records).to include(salary_record)
  end

  it "destroys dependent salary_records when destroyed" do
    employment = create(:employment)
    salary_record = create(:salary_record, employment: employment)

    employment.destroy!

    expect(SalaryRecord.exists?(salary_record.id)).to be false
  end
end
