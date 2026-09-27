require "rails_helper"

RSpec.describe "Payslips", type: :request do
  let(:headers) { auth_headers }

  describe "GET /payslips/:id" do
    it "shows the payslip with its reference" do
      employee = create(:employee, :with_salary)
      line_item = create(:payroll_line_item, employee: employee, salary_record: employee.current_salary_record)
      payslip = create(:payslip, payroll_line_item: line_item)

      get payslip_path(payslip), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(payslip.reference)
      expect(response.body).to include(employee.full_name)
    end

    it "returns 404 for an unknown payslip" do
      get payslip_path(0), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
