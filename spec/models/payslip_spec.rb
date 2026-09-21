require "rails_helper"

RSpec.describe Payslip, type: :model do
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
  let(:payroll_run) do
    PayrollRun.create!(period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))
  end

  def build_payslip(attributes = {})
    Payslip.new(
      {
        payroll_run: payroll_run,
        employee: employee,
        payslip_number: "PS-2026-09-1001",
        status: "generated"
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_payslip).to be_valid
  end

  it "is invalid without a payroll_run" do
    payslip = build_payslip(payroll_run: nil)

    expect(payslip).not_to be_valid
    expect(payslip.errors[:payroll_run]).to include("must exist")
  end

  it "is invalid without an employee" do
    payslip = build_payslip(employee: nil)

    expect(payslip).not_to be_valid
    expect(payslip.errors[:employee]).to include("must exist")
  end

  it "is invalid without a payslip_number" do
    payslip = build_payslip(payslip_number: nil)

    expect(payslip).not_to be_valid
    expect(payslip.errors[:payslip_number]).to include("can't be blank")
  end

  it "is invalid with a duplicate payslip_number" do
    build_payslip.save!
    duplicate = build_payslip(payslip_number: "PS-2026-09-1001", employee: employee)
    duplicate.payroll_run = PayrollRun.create!(period_start: Date.new(2026, 10, 1), period_end: Date.new(2026, 10, 31))

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:payslip_number]).to include("has already been taken")
  end

  it "is invalid when the employee already has a payslip for the same payroll_run" do
    build_payslip.save!
    duplicate = build_payslip(payslip_number: "PS-2026-09-1002")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:employee_id]).to include("has already been taken")
  end
end
