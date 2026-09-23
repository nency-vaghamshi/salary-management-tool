require "rails_helper"

RSpec.describe Employee, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:employee)).to be_valid
  end

  it "is invalid without an employee_number" do
    employee = build_stubbed(:employee, employee_number: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:employee_number]).to include("can't be blank")
  end

  it "is invalid with a duplicate employee_number" do
    create(:employee, employee_number: "EMP-1001")
    duplicate = build(:employee, employee_number: "EMP-1001")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:employee_number]).to include("has already been taken")
  end

  it "is invalid without a first_name" do
    employee = build_stubbed(:employee, first_name: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:first_name]).to include("can't be blank")
  end

  it "is invalid without a last_name" do
    employee = build_stubbed(:employee, last_name: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:last_name]).to include("can't be blank")
  end

  it "is invalid without an email" do
    employee = build_stubbed(:employee, email: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:email]).to include("can't be blank")
  end

  it "is invalid with a duplicate email" do
    create(:employee, email: "ada@example.com")
    duplicate = build(:employee, email: "ada@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "is invalid without a department" do
    employee = build_stubbed(:employee, department: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:department]).to include("must exist")
  end

  it "is invalid without a job_title" do
    employee = build_stubbed(:employee, job_title: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:job_title]).to include("must exist")
  end

  it "is valid without a nationality_country" do
    expect(build_stubbed(:employee, nationality_country: nil)).to be_valid
  end

  it "is valid without a residence_country" do
    expect(build_stubbed(:employee, residence_country: nil)).to be_valid
  end

  it "is valid with a nationality_country and residence_country set independently" do
    nationality = build_stubbed(:country, :united_states)
    residence = build_stubbed(:country, :india)
    employee = build_stubbed(:employee, nationality_country: nationality, residence_country: residence)

    expect(employee).to be_valid
    expect(employee.nationality_country).to eq(nationality)
    expect(employee.residence_country).to eq(residence)
  end

  it "has many employments" do
    employee = create(:employee)
    employment = create(:employment, employee: employee)

    expect(employee.employments).to include(employment)
  end

  it "has many salary_records through employments" do
    employee = create(:employee)
    employment = create(:employment, employee: employee)
    salary_record = create(:salary_record, employment: employment)

    expect(employee.salary_records).to include(salary_record)
  end

  it "has many payroll_line_items" do
    employee = create(:employee)
    line_item = create(:payroll_line_item, employee: employee)

    expect(employee.payroll_line_items).to include(line_item)
  end

  it "has many payslips through payroll_line_items" do
    employee = create(:employee)
    line_item = create(:payroll_line_item, employee: employee)
    payslip = create(:payslip, payroll_line_item: line_item)

    expect(employee.payslips).to include(payslip)
  end
end
