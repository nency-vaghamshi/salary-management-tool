require "rails_helper"

RSpec.describe "Employees", type: :request do
  let(:headers) { auth_headers }
  let(:department) { create(:department) }
  let(:job_title) { create(:job_title) }
  let(:valid_params) do
    { employee: { employee_number: "EMP-9001", first_name: "Ada", last_name: "Lovelace", email: "ada@example.com",
                  department_id: department.id, job_title_id: job_title.id } }
  end

  describe "GET /employees" do
    it "lists employees" do
      create(:employee, first_name: "Ada", last_name: "Lovelace")

      get employees_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Lovelace")
    end

    it "filters by the search query" do
      create(:employee, first_name: "Ada", last_name: "Lovelace")
      create(:employee, first_name: "Grace", last_name: "Hopper")

      get employees_path, params: { q: "grace" }, headers: headers

      expect(response.body).to include("Grace Hopper")
      expect(response.body).not_to include("Ada Lovelace")
    end

    it "shows the empty state when no employee matches" do
      create(:employee)

      get employees_path, params: { q: "nobody-matches-this" }, headers: headers

      expect(response.body).to include("No employees match these filters")
    end

    it "offers departments in the search filters" do
      create(:department, name: "Research")

      get employees_path, headers: headers

      expect(response.body).to include("Research")
    end
  end

  describe "GET /employees/:id" do
    it "shows the employee with their salary" do
      employee = create(:employee, :with_salary, salary_amount: 100_000)

      get employee_path(employee), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(employee.full_name)
    end

    it "shows an employee with no salary yet" do
      employee = create(:employee)

      get employee_path(employee), headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for an unknown employee" do
      get employee_path(0), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /employees/new" do
    it "renders the form" do
      get new_employee_path, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /employees" do
    it "creates the employee and redirects to it" do
      expect { post employees_path, params: valid_params, headers: headers }.to change(Employee, :count).by(1)

      expect(response).to redirect_to(employee_path(Employee.last))
      expect(flash[:notice]).to eq("Employee created.")
    end

    it "re-renders the form with 422 when invalid" do
      invalid = valid_params.deep_merge(employee: { email: "" })

      expect { post employees_path, params: invalid, headers: headers }.not_to change(Employee, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /employees/:id/edit" do
    it "renders the form" do
      get edit_employee_path(create(:employee)), headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /employees/:id" do
    let(:employee) { create(:employee, first_name: "Ada") }

    it "updates the employee and redirects to it" do
      patch employee_path(employee), params: { employee: { first_name: "Grace" } }, headers: headers

      expect(response).to redirect_to(employee_path(employee))
      expect(employee.reload.first_name).to eq("Grace")
    end

    it "re-renders the form with 422 when invalid" do
      patch employee_path(employee), params: { employee: { first_name: "" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.first_name).to eq("Ada")
    end
  end

  describe "DELETE /employees/:id" do
    it "removes the employee, including their salary history" do
      employee = create(:employee, :with_salary)

      expect { delete employee_path(employee), headers: headers }.to change(Employee, :count).by(-1)
                                                               .and change(SalaryRecord, :count).by(-1)

      expect(response).to redirect_to(employees_path)
    end
  end
end
