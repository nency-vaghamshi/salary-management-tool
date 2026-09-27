require "rails_helper"

RSpec.describe EmployeeDataSeeder, type: :model do
  let(:payroll_country) { create(:country, :india) }
  let!(:tax_configuration) { create(:tax_configuration, country: payroll_country) }
  let!(:untaxed_country) { create(:country) }
  let!(:department) { create(:department) }
  let!(:job_title) { create(:job_title) }
  let!(:base_component) { create(:salary_component, code: "BASE", is_taxable: true) }
  let!(:housing_component) { create(:salary_component, code: "HOUSING", is_taxable: false) }

  describe ".call" do
    it "creates the requested number of employees and returns the count" do
      expect(described_class.call(3)).to eq(3)
      expect(Employee.count).to eq(3)
    end

    it "gives every employee an active employment paid in a taxable country" do
      described_class.call(5)

      employments = Employment.all
      expect(employments.size).to eq(5)
      expect(employments.map(&:status).uniq).to eq([ "active" ])
      expect(employments.map(&:payroll_country_id).uniq).to eq([ payroll_country.id ])
      expect(Employee.pluck(:residence_country_id).uniq).to eq([ payroll_country.id ])
    end

    it "gives every employment an open-ended salary record in the payroll country's currency" do
      described_class.call(5)

      SalaryRecord.includes(:employment, :salary_record_components).find_each do |salary_record|
        expect(salary_record.effective_to).to be_nil
        expect(salary_record.effective_from).to eq(salary_record.employment.start_date)
        expect(salary_record.currency_id).to eq(payroll_country.currency_id)
        expect(salary_record.salary_record_components.map(&:salary_component_id))
          .to contain_exactly(base_component.id, housing_component.id)
      end
    end

    it "produces employees a payroll run can process" do
      described_class.call(1)

      employee = Employee.sole
      expect(employee.current_employment).to be_active
      expect(employee.current_salary_record.total_amount).to be_positive
    end

    it "keeps employee numbers and emails unique across batches" do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      described_class.call(5)

      expect(Employee.distinct.count(:email)).to eq(5)
      expect(Employee.order(:employee_number).pluck(:employee_number))
        .to eq(%w[EMP-00001 EMP-00002 EMP-00003 EMP-00004 EMP-00005])
    end

    it "continues numbering after the highest existing EMP number, compared numerically" do
      create(:employee, employee_number: "EMP-9999")
      create(:employee, employee_number: "CONTRACTOR-7")

      described_class.call(1)

      expect(Employee.exists?(employee_number: "EMP-10000")).to be(true)
    end

    it "does not write audit log entries" do
      expect { described_class.call(2) }.not_to change(AuditLog, :count)
    end

    it "does nothing when count is zero" do
      expect(described_class.call(0)).to eq(0)
      expect(Employee.count).to eq(0)
    end

    it "rejects a negative count" do
      expect { described_class.call(-1) }.to raise_error(ArgumentError, /non-negative integer/)
    end

    it "rejects a non-integer count" do
      expect { described_class.call("10") }.to raise_error(ArgumentError, /non-negative integer/)
    end

    it "raises when no country has a tax configuration" do
      tax_configuration.destroy!

      expect { described_class.call(1) }
        .to raise_error(described_class::MissingReferenceDataError, /countries with a tax configuration/)
      expect(Employee.count).to eq(0)
    end

    it "raises when the BASE salary component is missing" do
      base_component.destroy!

      expect { described_class.call(1) }
        .to raise_error(described_class::MissingReferenceDataError, /BASE salary component/)
    end
  end
end
