require "rails_helper"

RSpec.describe Country, type: :model do
  let(:currency) { Currency.create!(code: "USD", name: "US Dollar", symbol: "$") }

  it "is valid with a name, code, and currency" do
    country = Country.new(name: "United States", code: "US", currency: currency)

    expect(country).to be_valid
  end

  it "is invalid without a name" do
    country = Country.new(name: nil, code: "US", currency: currency)

    expect(country).not_to be_valid
    expect(country.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    country = Country.new(name: "United States", code: nil, currency: currency)

    expect(country).not_to be_valid
    expect(country.errors[:code]).to include("can't be blank")
  end

  it "is invalid without a currency" do
    country = Country.new(name: "United States", code: "US", currency: nil)

    expect(country).not_to be_valid
    expect(country.errors[:currency]).to include("must exist")
  end

  it "is invalid with a duplicate code" do
    Country.create!(name: "United States", code: "US", currency: currency)
    duplicate = Country.new(name: "United States of America", code: "US", currency: currency)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end

  it "has many employees" do
    country = Country.create!(name: "United States", code: "US", currency: currency)
    department = Department.create!(name: "Engineering", code: "ENG")
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

    expect(country.employees).to include(employee)
  end
end
