require "rails_helper"

RSpec.describe PayrollLineItem, type: :model do
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
    SalaryRecord.create!(employee: employee, currency: currency, effective_from: Date.new(2024, 4, 1))
  end
  let(:basic_salary) do
    SalaryComponent.create!(name: "Basic Salary", code: "BASIC", component_type: "earning", calculation_type: "fixed")
  end
  let(:payroll_run) do
    PayrollRun.create!(period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))
  end

  def build_line_item(attributes = {})
    PayrollLineItem.new(
      {
        payroll_run: payroll_run,
        employee: employee,
        salary_record: salary_record,
        salary_component: basic_salary,
        component_type: "earning",
        amount: 70_000.00
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_line_item).to be_valid
  end

  it "is invalid without a payroll_run" do
    line_item = build_line_item(payroll_run: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:payroll_run]).to include("must exist")
  end

  it "is invalid without an employee" do
    line_item = build_line_item(employee: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:employee]).to include("must exist")
  end

  it "is invalid without a salary_record" do
    line_item = build_line_item(salary_record: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:salary_record]).to include("must exist")
  end

  it "is invalid without a salary_component" do
    line_item = build_line_item(salary_component: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:salary_component]).to include("must exist")
  end

  it "is invalid without an amount" do
    line_item = build_line_item(amount: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:amount]).to include("can't be blank")
  end

  it "rejects a component_type outside earning/deduction" do
    expect { build_line_item(component_type: "bonus") }.to raise_error(ArgumentError)
  end

  it "snapshots component_type from the salary_component when not explicitly set" do
    line_item = build_line_item(component_type: nil)
    line_item.save!

    expect(line_item.component_type).to eq("earning")
  end
end
