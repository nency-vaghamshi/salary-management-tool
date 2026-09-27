require "rails_helper"

RSpec.describe "API v1 salary records", type: :request do
  let(:headers) { auth_headers }
  let(:employee) { create(:employee, :with_salary) }
  let(:employment) { employee.current_employment }
  let(:currency) { create(:currency) }
  let(:component) { create(:salary_component) }

  describe "POST /api/v1/salary_records" do
    def post_revision(components:, effective_from: "2026-01-01", employment_id: employment.id)
      post api_v1_salary_records_path, params: { employment_id: employment_id, currency_id: currency.id,
                                                 effective_from: effective_from, components: components },
                                       headers: headers, as: :json
    end

    it "creates the new salary record and closes the previous one" do
      previous = employee.current_salary_record

      expect { post_revision(components: { component.id => "95000" }) }.to change(SalaryRecord, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["salary_record"]).to include("employment_id" => employment.id, "effective_from" => "2026-01-01",
                                               "status" => "active", "total_amount" => "95000.0")
      expect(previous.reload).to be_inactive
    end

    it "ignores blank component amounts" do
      post_revision(components: { component.id => "95000", create(:salary_component).id => "" })

      expect(json["salary_record"]["components"].size).to eq(1)
    end

    it "returns 422 when no component amount is given" do
      post_revision(components: {})

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([ "At least one salary component is required" ])
    end

    it "returns 422 for an invalid effective_from" do
      post_revision(components: { component.id => "95000" }, effective_from: "not-a-date")

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([ "Effective from is not a valid date" ])
    end

    it "returns 404 for an unknown employment" do
      post_revision(components: { component.id => "95000" }, employment_id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/salary_records/:id" do
    it "returns the record with its components and tax estimate" do
      employee = create(:employee, :with_salary, salary_amount: 100_000, tax_rate: 10)

      get api_v1_salary_record_path(employee.current_salary_record), headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["salary_record"]["components"].sole["amount"]).to eq("100000.0")
      expect(json["salary_record"]["tax_estimate"]).to include("tax_amount" => "10000.0", "net_amount" => "90000.0")
    end

    it "returns 404 for an unknown record" do
      get api_v1_salary_record_path(0), headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
