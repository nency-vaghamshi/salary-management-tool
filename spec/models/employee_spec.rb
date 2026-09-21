require "rails_helper"

RSpec.describe Employee, type: :model do
  let(:currency) { Currency.create!(code: "USD", name: "US Dollar", symbol: "$") }
  let(:country) { Country.create!(name: "United States", code: "US", currency: currency) }
  let(:department) { Department.create!(name: "Engineering", code: "ENG") }
  let(:job_title) { JobTitle.create!(name: "Software Engineer", code: "SWE") }

  def build_employee(attributes = {})
    Employee.new(
      {
        employee_number: "EMP-1001",
        first_name: "Ada",
        last_name: "Lovelace",
        email: "ada@example.com",
        department: department,
        job_title: job_title,
        country: country,
        employment_status: "active",
        joined_on: Date.new(2026, 1, 1)
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_employee).to be_valid
  end

  it "is invalid without an employee_number" do
    employee = build_employee(employee_number: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:employee_number]).to include("can't be blank")
  end

  it "is invalid with a duplicate employee_number" do
    build_employee.save!
    duplicate = build_employee(email: "grace@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:employee_number]).to include("has already been taken")
  end

  it "is invalid without a first_name" do
    employee = build_employee(first_name: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:first_name]).to include("can't be blank")
  end

  it "is invalid without a last_name" do
    employee = build_employee(last_name: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:last_name]).to include("can't be blank")
  end

  it "is invalid without an email" do
    employee = build_employee(email: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:email]).to include("can't be blank")
  end

  it "is invalid with a duplicate email" do
    build_employee.save!
    duplicate = build_employee(employee_number: "EMP-1002")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "is invalid without a department" do
    employee = build_employee(department: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:department]).to include("must exist")
  end

  it "is invalid without a job_title" do
    employee = build_employee(job_title: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:job_title]).to include("must exist")
  end

  it "is invalid without a country" do
    employee = build_employee(country: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:country]).to include("must exist")
  end

  it "is invalid without a joined_on date" do
    employee = build_employee(joined_on: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:joined_on]).to include("can't be blank")
  end

  it "defaults to the active employment_status when not specified" do
    employee = Employee.new(
      employee_number: "EMP-1001",
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada@example.com",
      department: department,
      job_title: job_title,
      country: country,
      joined_on: Date.new(2026, 1, 1)
    )

    expect(employee.employment_status).to eq("active")
  end

  it "rejects an employment_status outside the defined set" do
    expect { build_employee(employment_status: "on_vacation") }.to raise_error(ArgumentError)
  end

  it "has many salary_records" do
    employee = build_employee
    employee.save!
    salary_record = SalaryRecord.create!(
      employee: employee,
      currency: currency,
      effective_from: Date.new(2024, 4, 1),
      effective_to: nil,
      status: "active"
    )

    expect(employee.salary_records).to include(salary_record)
  end
end
