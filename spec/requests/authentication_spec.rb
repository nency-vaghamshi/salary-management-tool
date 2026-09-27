require "rails_helper"

# Authenticatable + ApplicationController: every page and endpoint is behind
# the JWT check unless it explicitly opts out.
RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user) }

  context "for HTML pages" do
    it "redirects to the login page without a token" do
      get employees_path

      expect(response).to redirect_to(login_path)
    end

    it "lets a request with a valid Bearer token through" do
      get employees_path, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
    end

    it "lets a request with the signed jwt cookie through, as the browser sends it" do
      post api_v1_auth_login_path, params: { email: user.email, password: "SecurePass123!" }, as: :json

      get employees_path

      expect(response).to have_http_status(:ok)
    end
  end

  context "for JSON endpoints" do
    it "returns 401 without a token" do
      get api_v1_employees_path, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("error" => "Unauthorized")
    end

    it "returns 401 for a malformed token" do
      get api_v1_employees_path, headers: { "Authorization" => "Bearer not-a-jwt" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for an expired token" do
      token = JsonWebToken.encode({ user_id: user.id }, exp: 1.minute.ago)

      get api_v1_employees_path, headers: { "Authorization" => "Bearer #{token}" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the token's user no longer exists" do
      headers = auth_headers(user)
      user.destroy!

      get api_v1_employees_path, headers: headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "ignores an Authorization header that is not a Bearer token" do
      get api_v1_employees_path, headers: { "Authorization" => "Basic abc123" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "attributes changes made during the request to the signed-in user" do
    employee = create(:employee)

    patch employee_path(employee), params: { employee: { first_name: "Changed" } }, headers: auth_headers(user)

    expect(AuditLog.where(auditable: employee, action: "updated").sole.actor).to eq(user)
  end
end
