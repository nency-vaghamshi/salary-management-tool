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
      nationality = create(:country)
      create(:employee, :with_salary, nationality_country: nationality, salary_amount: 100_000)

      get api_v1_employees_path, headers: headers, as: :json

      expect(json["employees"].first).to include("nationality_country" => nationality.name, "employment_status" => "active",
                                                 "current_salary" => "100000.0")
    end

    it "filters by the search query" do
      create(:employee)
      target = create(:employee)

      get api_v1_employees_path, params: { q: target.email }, headers: headers

      expect(json["employees"].map { |employee| employee["id"] }).to eq([ target.id ])
    end

    it "returns an empty list when there are no employees" do
      get api_v1_employees_path, headers: headers, as: :json

      expect(json["employees"]).to eq([])
      expect(json["pagination"]).to include("count" => 0)
    end

    it "paginates the roster" do
      create_list(:employee, Pagy::DEFAULT[:limit] + 1)

      get api_v1_employees_path, params: { page: 2 }, headers: headers

      expect(json["employees"].size).to eq(1)
      expect(json["pagination"]).to include("page" => 2, "pages" => 2)
    end

    it "filters by department" do
      department = create(:department)
      create(:employee, department: department, first_name: "Inside")
      create(:employee, first_name: "Outside")

      get api_v1_employees_path, params: { department_id: department.id }, headers: headers

      expect(json["employees"].map { |employee| employee["first_name"] }).to eq([ "Inside" ])
    end

    it "sorts by the requested column and direction" do
      first, second = create_list(:employee, 2)

      get api_v1_employees_path, params: { sort: "employee_number", direction: "desc" }, headers: headers

      expect(json["employees"].map { |employee| employee["id"] }).to eq([ second.id, first.id ])
    end

    it "falls back to the default sort for an unknown column" do
      create_list(:employee, 2)

      get api_v1_employees_path, params: { sort: "password; DROP TABLE employees" }, headers: headers

      expect(response).to have_http_status(:ok)
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
      country = create(:country)
      employment = create(:employment, employee: employee, payroll_country: country)
      create(:salary_record_component, salary_record: create(:salary_record, employment: employment))

      get api_v1_employee_path(employee), headers: headers, as: :json

      expect(json["employee"]["tax_estimate"]).to eq("error" => "No tax configuration found for #{country.name}")
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

  describe "POST /api/v1/employees (validation)" do
    it "returns 422 for a duplicate employee number" do
      existing = create(:employee)
      attributes = attributes_for(:employee).merge(employee_number: existing.employee_number,
                                                   department_id: create(:department).id, job_title_id: create(:job_title).id)

      post api_v1_employees_path, params: { employee: attributes }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the department doesn't exist" do
      attributes = attributes_for(:employee).merge(department_id: 0, job_title_id: create(:job_title).id)

      expect { post api_v1_employees_path, params: { employee: attributes }, headers: headers, as: :json }.not_to change(Employee, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee) }
    let(:new_first_name) { generate(:person_name) }

    it "updates the employee" do
      patch api_v1_employee_path(employee), params: { employee: { first_name: new_first_name } }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(employee.reload.first_name).to eq(new_first_name)
    end

    it "returns 422 with the validation errors" do
      original_first_name = employee.first_name

      patch api_v1_employee_path(employee), params: { employee: { first_name: "" } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.first_name).to eq(original_first_name)
    end
  end

  describe "PATCH /api/v1/employees/:id (not found)" do
    it "returns 404 for an unknown employee" do
      patch api_v1_employee_path(0), params: { employee: { first_name: generate(:person_name) } }, headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Resource not found")
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    it "removes the employee" do
      employee = create(:employee)

      expect { delete api_v1_employee_path(employee), headers: headers, as: :json }.to change(Employee, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for an unknown employee" do
      delete api_v1_employee_path(0), headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
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

  describe "GET /api/v1/employees/:id/salary_history (edge cases)" do
    it "returns an empty history for an employee without salary records" do
      get salary_history_api_v1_employee_path(create(:employee)), headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["salary_history"]).to eq([])
    end

    it "returns 404 for an unknown employee" do
      get salary_history_api_v1_employee_path(0), headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
