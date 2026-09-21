require "rails_helper"

RSpec.describe Employee, type: :model do
  let(:currency) { Currency.create!(code: "INR", name: "Indian Rupee", symbol: "₹") }
  let(:department) { Department.create!(name: "Engineering", code: "ENG") }
  let(:job_title) { JobTitle.create!(name: "Software Engineer", code: "SWE") }
  let(:country) { Country.create!(name: "India", code: "IN", currency: currency) }

  subject(:employee) do
    described_class.new(
      employee_number: "EMP-1001",
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada.lovelace@example.com",
      department: department,
      job_title: job_title,
      country: country,
      employment_status: "active",
      joined_on: Date.new(2024, 4, 1)
    )
  end

  it "is valid with all required attributes" do
    expect(employee).to be_valid
  end

  it "is invalid without an employee_number" do
    employee.employee_number = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:employee_number]).to include("can't be blank")
  end

  it "is invalid with a duplicate employee_number" do
    employee.dup.tap { |e| e.email = "other@example.com" }.save!
    employee.email = "another@example.com"

    expect(employee).not_to be_valid
    expect(employee.errors[:employee_number]).to include("has already been taken")
  end

  it "is invalid without a first_name" do
    employee.first_name = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:first_name]).to include("can't be blank")
  end

  it "is invalid without a last_name" do
    employee.last_name = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:last_name]).to include("can't be blank")
  end

  it "is invalid without an email" do
    employee.email = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:email]).to include("can't be blank")
  end

  it "is invalid with a duplicate email" do
    employee.dup.tap { |e| e.employee_number = "EMP-1002" }.save!
    employee.employee_number = "EMP-1003"

    expect(employee).not_to be_valid
    expect(employee.errors[:email]).to include("has already been taken")
  end

  it "is invalid without an employment_status" do
    employee.employment_status = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:employment_status]).to include("can't be blank")
  end

  it "is invalid without a joined_on date" do
    employee.joined_on = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:joined_on]).to include("can't be blank")
  end

  it "is invalid without a department" do
    employee.department = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:department]).to include("must exist")
  end

  it "is invalid without a job_title" do
    employee.job_title = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:job_title]).to include("must exist")
  end

  it "is invalid without a country" do
    employee.country = nil

    expect(employee).not_to be_valid
    expect(employee.errors[:country]).to include("must exist")
  end
end
