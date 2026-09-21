require "rails_helper"

RSpec.describe SalaryRecordComponent, type: :model do
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
  let(:salary_record) do
    SalaryRecord.create!(
      employee: employee,
      currency: currency,
      effective_from: Date.new(2024, 4, 1),
      effective_to: nil,
      status: "active"
    )
  end
  let(:basic_salary) do
    SalaryComponent.create!(name: "Basic Salary", code: "BASIC", component_type: "earning", calculation_type: "fixed")
  end

  def build_line(attributes = {})
    SalaryRecordComponent.new(
      {
        salary_record: salary_record,
        salary_component: basic_salary,
        amount: 70_000.00
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_line).to be_valid
  end

  it "is invalid without a salary_record" do
    line = build_line(salary_record: nil)

    expect(line).not_to be_valid
    expect(line.errors[:salary_record]).to include("must exist")
  end

  it "is invalid without a salary_component" do
    line = build_line(salary_component: nil)

    expect(line).not_to be_valid
    expect(line.errors[:salary_component]).to include("must exist")
  end

  it "is invalid without an amount" do
    line = build_line(amount: nil)

    expect(line).not_to be_valid
    expect(line.errors[:amount]).to include("can't be blank")
  end

  it "is invalid with a negative amount" do
    line = build_line(amount: -100)

    expect(line).not_to be_valid
    expect(line.errors[:amount]).to include("must be greater than or equal to 0")
  end

  it "is invalid when the same component appears twice in the same salary record" do
    build_line.save!
    duplicate = build_line(amount: 5_000.00)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:salary_component_id]).to include("has already been taken")
  end

  it "snapshots calculation_type from the salary_component when not explicitly set" do
    line = build_line
    line.save!

    expect(line.calculation_type).to eq("fixed")
  end

  it "allows the calculation_type snapshot to be explicitly overridden" do
    line = build_line(calculation_type: "percentage")
    line.save!

    expect(line.calculation_type).to eq("percentage")
  end
end
