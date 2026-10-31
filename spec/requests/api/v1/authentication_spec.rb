require "rails_helper"

# Api::V1::BaseController: every endpoint is behind devise-jwt and must
# answer 401 JSON (never a redirect) when the token is missing or unusable.
RSpec.describe "API v1 authentication", type: :request do
  let(:user) { create(:user) }
  let(:employee) { create(:employee) }

  protected_endpoints = {
    "GET /api/v1/employees" => -> { get api_v1_employees_path, as: :json },
    "GET /api/v1/employees/:id" => -> { get api_v1_employee_path(employee), as: :json },
    "POST /api/v1/employees" => -> { post api_v1_employees_path, params: { employee: { first_name: "A" } }, as: :json },
    "PATCH /api/v1/employees/:id" => -> { patch api_v1_employee_path(employee), params: { employee: { first_name: "A" } }, as: :json },
    "DELETE /api/v1/employees/:id" => -> { delete api_v1_employee_path(employee), as: :json },
    "GET /api/v1/employees/:id/salary_history" => -> { get salary_history_api_v1_employee_path(employee), as: :json },
    "POST /api/v1/salary_records" => -> { post api_v1_salary_records_path, params: {}, as: :json },
    "GET /api/v1/salary_records/:id" => -> { get api_v1_salary_record_path(0), as: :json }
  }

  protected_endpoints.each do |label, request|
    it "returns 401 for #{label} without a token" do
      instance_exec(&request)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "returns 401 for a malformed token" do
    get api_v1_employees_path, headers: { "Authorization" => "Bearer not-a-jwt" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 for an expired token" do
    headers = auth_headers(user)

    travel_to(31.minutes.from_now) do
      get api_v1_employees_path, headers: headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "returns 401 once the user's token has been rotated (jti changed)" do
    headers = auth_headers(user)
    user.update_column(:jti, SecureRandom.uuid)

    get api_v1_employees_path, headers: headers, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 when the token's user no longer exists" do
    headers = auth_headers(user)
    user.destroy!

    get api_v1_employees_path, headers: headers, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "ignores the web cookies so the API only trusts the explicit header" do
    post user_session_path, params: { user: { email: user.email, password: user.password } }, as: :json
    expect(response.cookies["jwt"]).to be_present

    get api_v1_employees_path, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
