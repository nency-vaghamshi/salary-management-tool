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

  it "destroys dependent employments when destroyed" do
    employee = create(:employee)
    create(:employment, employee: employee)

    expect { employee.destroy! }.to change(Employment, :count).by(-1)
  end

  it "creates employments through nested attributes" do
    employee = build(:employee, employments_attributes: [ { payroll_country: create(:country), start_date: Date.new(2025, 1, 1) } ])

    expect { employee.save! }.to change(Employment, :count).by(1)
  end

  describe "#full_name" do
    it "joins the first and last name" do
      expect(build_stubbed(:employee, first_name: "Ada", last_name: "Lovelace").full_name).to eq("Ada Lovelace")
    end
  end

  describe "#current_employment" do
    let(:employee) { create(:employee) }

    it "prefers the open-ended employment over a more recently started ended one" do
      open_ended = create(:employment, employee: employee, start_date: Date.new(2020, 1, 1), end_date: nil)
      create(:employment, employee: employee, start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 6, 30))

      expect(employee.reload.current_employment).to eq(open_ended)
    end

    it "falls back to the most recently started employment when all have ended" do
      create(:employment, employee: employee, start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 12, 31))
      latest = create(:employment, employee: employee, start_date: Date.new(2023, 1, 1), end_date: Date.new(2023, 12, 31))

      expect(employee.reload.current_employment).to eq(latest)
    end

    it "still returns a terminated employment, so HR can see an ex-employee's last job" do
      terminated = create(:employment, employee: employee, status: "terminated", end_date: Date.new(2025, 12, 31))

      expect(employee.reload.current_employment).to eq(terminated)
    end

    it "returns nil when the employee has no employment" do
      expect(employee.current_employment).to be_nil
    end
  end

  describe "#current_salary_record" do
    let(:employee) { create(:employee) }
    let(:employment) { create(:employment, employee: employee) }

    it "returns the latest salary record of the current employment" do
      create(:salary_record, employment: employment, effective_from: Date.new(2024, 4, 1), effective_to: Date.new(2024, 12, 31))
      latest = create(:salary_record, employment: employment, effective_from: Date.new(2025, 1, 1))

      expect(employee.reload.current_salary_record).to eq(latest)
    end

    it "ignores salary records from a previous employment" do
      old_employment = create(:employment, employee: employee, start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 12, 31))
      create(:salary_record, employment: old_employment, effective_from: Date.new(2020, 1, 1))
      current = create(:salary_record, employment: employment)

      expect(employee.reload.current_salary_record).to eq(current)
    end

    it "returns nil when there is no employment" do
      expect(employee.current_salary_record).to be_nil
    end

    it "returns nil when the current employment has no salary record" do
      employment

      expect(employee.reload.current_salary_record).to be_nil
    end
  end
end
