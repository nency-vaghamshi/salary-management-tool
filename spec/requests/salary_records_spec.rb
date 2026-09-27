require "rails_helper"

RSpec.describe "Salary records", type: :request do
  let(:headers) { auth_headers }
  let(:currency) { create(:currency) }
  let(:component) { create(:salary_component) }

  describe "GET /salary_records/new" do
    it "asks for a payroll country when this is the employee's first salary" do
      create(:country, name: "Portugal")

      get new_salary_record_path(employee_id: create(:employee).id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("payroll_country_id")
    end

    it "does not ask for a payroll country when the employee already has an employment" do
      employee = create(:employee, :with_salary)

      get new_salary_record_path(employee_id: employee.id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("payroll_country_id")
    end
  end

  describe "POST /salary_records" do
    it "revises the salary, closing the previous record" do
      employee = create(:employee, :with_salary)
      previous = employee.current_salary_record

      expect {
        post salary_records_path, params: { employee_id: employee.id, currency_id: currency.id, effective_from: "2026-01-01",
                                            components: { component.id => "95000" } }, headers: headers
      }.to change(SalaryRecord, :count).by(1)

      expect(response).to redirect_to(employee_path(employee))
      expect(previous.reload).to be_inactive
      expect(employee.reload.current_salary_record.total_amount).to eq(95_000)
    end

    it "creates the employment along with an employee's first salary" do
      employee = create(:employee)
      country = create(:country)

      expect {
        post salary_records_path, params: { employee_id: employee.id, payroll_country_id: country.id, start_date: "2026-01-01",
                                            currency_id: currency.id, effective_from: "2026-01-01",
                                            components: { component.id => "60000" } }, headers: headers
      }.to change(Employment, :count).by(1)

      expect(employee.reload.current_employment.payroll_country).to eq(country)
      expect(response).to redirect_to(employee_path(employee))
    end

    it "re-renders the form with the errors when no component amount is given" do
      employee = create(:employee, :with_salary)

      expect {
        post salary_records_path, params: { employee_id: employee.id, currency_id: currency.id, effective_from: "2026-01-01",
                                            components: { component.id => "" } }, headers: headers
      }.not_to change(SalaryRecord, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("At least one salary component is required")
    end

    it "does not leave an orphaned employment when a first salary is rejected" do
      employee = create(:employee)

      expect {
        post salary_records_path, params: { employee_id: employee.id, payroll_country_id: create(:country).id, start_date: "2026-01-01",
                                            currency_id: currency.id, effective_from: "not-a-date",
                                            components: { component.id => "60000" } }, headers: headers
      }.not_to change(Employment, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /salary_records/:id" do
    it "shows the salary record" do
      employee = create(:employee, :with_salary)

      get salary_record_path(employee.current_salary_record), headers: headers

      expect(response).to have_http_status(:ok)
    end
  end
end
