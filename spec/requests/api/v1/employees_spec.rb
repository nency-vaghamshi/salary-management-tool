require "rails_helper"

RSpec.describe "API v1 employees", type: :request do
  let(:headers) { auth_headers }

  describe "GET /api/v1/employees" do
    it "returns employees with pagination metadata" do
      create_list(:employee, 2)

      get api_v1_employees_path, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["employees"].size).to eq(2)
      expect(json["pagination"]).to include("page" => 1, "count" => 2)
    end

    it "includes countries and the current salary" do
      nationality = create(:country, name: "Portugal")
      create(:employee, :with_salary, nationality_country: nationality, salary_amount: 100_000)

      get api_v1_employees_path, headers: headers, as: :json

      expect(json["employees"].first).to include("nationality_country" => "Portugal", "employment_status" => "active",
                                                 "current_salary" => "100000.0")
    end

    it "filters by the search query" do
      create(:employee, first_name: "Ada")
      create(:employee, first_name: "Grace")

      get api_v1_employees_path, params: { q: "grace" }, headers: headers

      expect(json["employees"].map { |employee| employee["first_name"] }).to eq([ "Grace" ])
    end

    it "requires authentication" do
      get api_v1_employees_path, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "includes a tax estimate for the current salary" do
      employee = create(:employee, :with_salary, salary_amount: 100_000, tax_rate: 10)

      get api_v1_employee_path(employee), headers: headers, as: :json

      expect(json["employee"]["tax_estimate"]).to eq("taxable_income" => "100000.0", "tax_amount" => "10000.0", "net_amount" => "90000.0")
    end

    it "reports why tax can't be estimated instead of failing" do
      employee = create(:employee)
      employment = create(:employment, employee: employee, payroll_country: create(:country, name: "Nowhere"))
      create(:salary_record_component, salary_record: create(:salary_record, employment: employment))

      get api_v1_employee_path(employee), headers: headers, as: :json

      expect(json["employee"]["tax_estimate"]).to eq("error" => "No tax configuration found for Nowhere")
    end

    it "omits the tax estimate for an employee without a salary" do
      get api_v1_employee_path(create(:employee)), headers: headers, as: :json

      expect(json["employee"]).not_to have_key("tax_estimate")
    end

    it "returns 404 for an unknown employee" do
      get api_v1_employee_path(0), headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/employees" do
    let(:attributes) { attributes_for(:employee).merge(department_id: create(:department).id, job_title_id: create(:job_title).id) }

    it "creates the employee" do
      expect { post api_v1_employees_path, params: { employee: attributes }, headers: headers, as: :json }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["employee"]["email"]).to eq(attributes[:email])
    end

    it "returns 422 with the validation errors" do
      post api_v1_employees_path, params: { employee: attributes.merge(email: "") }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("Email can't be blank")
    end

    it "accepts attributes sent without the employee wrapper, as Rails wraps JSON params" do
      expect { post api_v1_employees_path, params: attributes, headers: headers, as: :json }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee, first_name: "Ada") }

    it "updates the employee" do
      patch api_v1_employee_path(employee), params: { employee: { first_name: "Grace" } }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(employee.reload.first_name).to eq("Grace")
    end

    it "returns 422 with the validation errors" do
      patch api_v1_employee_path(employee), params: { employee: { first_name: "" } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.first_name).to eq("Ada")
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    it "removes the employee" do
      employee = create(:employee)

      expect { delete api_v1_employee_path(employee), headers: headers, as: :json }.to change(Employee, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/employees/:id/salary_history" do
    it "returns every salary record, newest first, each with a tax estimate" do
      employee = create(:employee, :with_salary)
      employment = employee.current_employment
      SalaryRevisionService.new(employment: employment, currency: employment.salary_records.first.currency,
                                effective_from: Date.new(2025, 1, 1),
                                component_amounts: { create(:salary_component) => 120_000 }).call

      get salary_history_api_v1_employee_path(employee), headers: headers, as: :json

      history = json["salary_history"]
      expect(history.map { |record| record["status"] }).to eq(%w[active inactive])
      expect(history.first["effective_from"]).to eq("2025-01-01")
      expect(history).to all(have_key("tax_estimate"))
    end
  end
end
