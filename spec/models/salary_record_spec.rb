require "rails_helper"

RSpec.describe SalaryRecord, type: :model do
  let(:currency) { Currency.create!(code: "USD", name: "US Dollar", symbol: "$") }
  let(:country) { Country.create!(name: "United States", code: "US", currency: currency) }
  let(:department) { Department.create!(name: "Engineering", code: "ENG") }
  let(:job_title) { JobTitle.create!(name: "Software Engineer", code: "SWE") }
  let(:employee) do
    Employee.create!(
      employee_number: "EMP-1001",
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada@example.com",
      department: department,
      job_title: job_title,
      country: country,
      joined_on: Date.new(2024, 4, 1)
    )
  end

  def build_record(attributes = {})
    SalaryRecord.new(
      {
        employee: employee,
        currency: currency,
        effective_from: Date.new(2024, 4, 1),
        effective_to: Date.new(2025, 3, 31),
        status: "active"
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_record).to be_valid
  end

  it "is invalid without an employee" do
    record = build_record(employee: nil)

    expect(record).not_to be_valid
    expect(record.errors[:employee]).to include("must exist")
  end

  it "is invalid without a currency" do
    record = build_record(currency: nil)

    expect(record).not_to be_valid
    expect(record.errors[:currency]).to include("must exist")
  end

  it "is invalid without an effective_from date" do
    record = build_record(effective_from: nil)

    expect(record).not_to be_valid
    expect(record.errors[:effective_from]).to include("can't be blank")
  end

  it "is valid with a nil effective_to, representing an open-ended record" do
    record = build_record(effective_to: nil)

    expect(record).to be_valid
  end

  it "is invalid when effective_to is before effective_from" do
    record = build_record(effective_from: Date.new(2025, 4, 1), effective_to: Date.new(2025, 3, 31))

    expect(record).not_to be_valid
    expect(record.errors[:effective_to]).to include("must be on or after the effective_from date")
  end

  it "is invalid when its period overlaps an existing record for the same employee" do
    build_record(effective_from: Date.new(2024, 4, 1), effective_to: Date.new(2025, 3, 31)).save!
    overlapping = build_record(effective_from: Date.new(2024, 6, 1), effective_to: Date.new(2026, 5, 31))

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:effective_from]).to include("overlaps an existing salary record for this employee")
  end

  it "is valid when its period is adjacent to, but does not overlap, an existing record" do
    build_record(effective_from: Date.new(2024, 4, 1), effective_to: Date.new(2025, 3, 31)).save!
    adjacent = build_record(effective_from: Date.new(2025, 4, 1), effective_to: Date.new(2026, 3, 31))

    expect(adjacent).to be_valid
  end

  it "is invalid when the employee already has an open-ended salary record" do
    build_record(effective_from: Date.new(2024, 4, 1), effective_to: nil).save!
    another_open_ended = build_record(effective_from: Date.new(2025, 4, 1), effective_to: nil)

    expect(another_open_ended).not_to be_valid
    expect(another_open_ended.errors[:effective_to]).to include("only one open-ended salary record is allowed per employee")
  end

  it "has many payroll_line_items" do
    salary_record = build_record
    salary_record.save!
    salary_component = SalaryComponent.create!(name: "Basic Salary", code: "BASIC", component_type: "earning", calculation_type: "fixed")
    payroll_run = PayrollRun.create!(period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))
    line_item = PayrollLineItem.create!(
      payroll_run: payroll_run,
      employee: employee,
      salary_record: salary_record,
      salary_component: salary_component,
      component_type: "earning",
      amount: 70_000.00
    )

    expect(salary_record.payroll_line_items).to include(line_item)
  end
end
