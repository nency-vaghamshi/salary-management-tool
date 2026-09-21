require "rails_helper"

RSpec.describe Department, type: :model do
  it "is valid with a name and code" do
    department = Department.new(name: "Engineering", code: "ENG")

    expect(department).to be_valid
  end

  it "is invalid without a name" do
    department = Department.new(name: nil, code: "ENG")

    expect(department).not_to be_valid
    expect(department.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    department = Department.new(name: "Engineering", code: nil)

    expect(department).not_to be_valid
    expect(department.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    Department.create!(name: "Engineering", code: "ENG")
    duplicate = Department.new(name: "Engineering Duplicate", code: "ENG")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end

  it "has many employees" do
    department = Department.create!(name: "Engineering", code: "ENG")
    currency = Currency.create!(code: "USD", name: "US Dollar", symbol: "$")
    country = Country.create!(name: "United States", code: "US", currency: currency)
    job_title = JobTitle.create!(name: "Software Engineer", code: "SWE")
    employee = Employee.create!(
      employee_number: "EMP-1001",
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada@example.com",
      department: department,
      job_title: job_title,
      country: country,
      joined_on: Date.new(2026, 1, 1)
    )

    expect(department.employees).to include(employee)
  end
end
