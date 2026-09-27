require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:headers) { auth_headers }

  it "shows an empty state when nobody has an active salary yet" do
    get root_path, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No active salary records yet")
  end

  context "with salaries in more than one currency" do
    let(:usd) { create(:currency, :usd) }
    let(:inr) { create(:currency, :inr) }

    before do
      engineering = create(:department, name: "Engineering")
      finance = create(:department, name: "Finance")
      create(:employee, :with_salary, department: engineering, currency: usd, salary_amount: 120_000)
      create(:employee, :with_salary, department: engineering, currency: usd, salary_amount: 80_000)
      create(:employee, :with_salary, department: finance, currency: inr, salary_amount: 900_000)
    end

    it "defaults to the currency most employees are paid in" do
      get root_path, headers: headers

      expect(response.body).to include("US Dollar")
      expect(response.body).to include("Engineering")
      expect(response.body).not_to include("Finance")
    end

    it "shows only the selected currency's figures" do
      get root_path, params: { currency_id: inr.id }, headers: headers

      expect(response.body).to include("Finance")
      expect(response.body).not_to include("Engineering")
    end

    it "falls back to the default currency for an unknown currency_id" do
      get root_path, params: { currency_id: 0 }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Engineering")
    end
  end

  it "includes completed payroll runs in the monthly payroll table" do
    employee = create(:employee, :with_salary, currency: create(:currency, :usd))
    run = create(:payroll_run, period_start: Date.current.beginning_of_month, period_end: Date.current.end_of_month, status: "completed")
    create(:payroll_line_item, payroll_run: run, employee: employee, salary_record: employee.current_salary_record, amount: 7_500, tax_amount: 833)

    get root_path, headers: headers

    expect(response.body).not_to include("No completed payroll runs in USD yet")
  end
end
