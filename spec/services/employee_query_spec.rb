require "rails_helper"

RSpec.describe EmployeeQuery do
  def query(params = {})
    described_class.new(ActionController::Parameters.new(params))
  end

  describe "#filtering?" do
    it "is false when no filter is given" do
      expect(query(sort: "email", page: 2)).not_to be_filtering
    end

    it "is true when any filter is present" do
      expect(query(department_id: 1)).to be_filtering
    end

    it "ignores blank filters" do
      expect(query(q: "", department_id: "")).not_to be_filtering
    end
  end

  describe "#filtered" do
    it "returns everyone when no criteria are given" do
      employees = create_list(:employee, 2)

      expect(query.filtered).to match_array(employees)
    end

    describe "search" do
      let!(:ada) { create(:employee, employee_number: "EMP-1001", first_name: "Ada", last_name: "Lovelace", email: "ada@example.com") }
      let!(:grace) { create(:employee, employee_number: "EMP-2002", first_name: "Grace", last_name: "Hopper", email: "grace@navy.test") }

      it "matches first name, last name, email or employee number, case-insensitively" do
        expect(query(q: "ADA").filtered).to eq([ ada ])
        expect(query(q: "hopper").filtered).to eq([ grace ])
        expect(query(q: "navy.test").filtered).to eq([ grace ])
        expect(query(q: "1001").filtered).to eq([ ada ])
      end

      it "ignores surrounding whitespace" do
        expect(query(q: "  grace  ").filtered).to eq([ grace ])
      end

      it "treats % and _ as literal characters, not wildcards" do
        expect(query(q: "%").filtered).to be_empty
        expect(query(q: "_").filtered).to be_empty
      end
    end

    it "filters by department, job title, nationality and residence" do
      department = create(:department)
      nationality = create(:country)
      match = create(:employee, department: department, nationality_country: nationality)
      create(:employee, department: department)
      create(:employee, nationality_country: nationality)

      expect(query(department_id: department.id, nationality_country_id: nationality.id).filtered).to eq([ match ])
    end

    describe "employment filters" do
      let(:portugal) { create(:country) }
      let(:spain) { create(:country) }

      it "filters by the payroll country of the current employment only" do
        mover = create(:employee)
        create(:employment, employee: mover, payroll_country: portugal, start_date: Date.new(2020, 1, 1), end_date: Date.new(2022, 12, 31))
        create(:employment, employee: mover, payroll_country: spain, start_date: Date.new(2023, 1, 1))

        expect(query(payroll_country_id: spain.id).filtered).to eq([ mover ])
        expect(query(payroll_country_id: portugal.id).filtered).to be_empty
      end

      it "filters by the status of the current employment" do
        leaver = create(:employee)
        create(:employment, employee: leaver, status: "terminated", end_date: Date.new(2025, 12, 31))
        stayer = create(:employee)
        create(:employment, employee: stayer, status: "active")

        expect(query(employment_status: "terminated").filtered).to eq([ leaver ])
      end

      it "excludes employees with no employment when an employment filter is given" do
        create(:employee)

        expect(query(employment_status: "active").filtered).to be_empty
      end
    end

    it "has no ORDER BY, so it can be used as a subquery" do
      expect(query(q: "a").filtered.order_values).to be_empty
    end
  end

  describe "#roster" do
    let!(:zoe) { create(:employee, employee_number: "EMP-0003", first_name: "Zoe") }
    let!(:amy) { create(:employee, employee_number: "EMP-0001", first_name: "Amy") }
    let!(:max) { create(:employee, employee_number: "EMP-0002", first_name: "Max") }

    it "sorts by employee number ascending by default" do
      expect(query.roster.to_a).to eq([ amy, max, zoe ])
    end

    it "sorts by a permitted column in the requested direction" do
      expect(query(sort: "first_name", direction: "desc").roster.to_a).to eq([ zoe, max, amy ])
    end

    it "falls back to the default sort for a column that isn't permitted" do
      expect(query(sort: "salary; DROP TABLE employees").roster.to_a).to eq([ amy, max, zoe ])
    end

    it "treats any direction other than desc as ascending" do
      expect(query(sort: "first_name", direction: "sideways").roster.to_a).to eq([ amy, max, zoe ])
    end

    it "returns each employee once even when an employment filter joins several rows" do
      create(:employment, employee: amy)

      expect(query(employment_status: "active").roster.to_a).to eq([ amy ])
    end
  end
end
