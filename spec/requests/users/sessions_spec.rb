require "rails_helper"

RSpec.describe "Sessions API", type: :request do
  let(:user) { create(:user) }
  let(:credentials) { { user: { email: user.email, password: user.password } } }

  describe "POST /users/sign_in" do
    it "logs in and returns the user plus a bearer token" do
      post user_session_path, params: credentials, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["status"]).to include("code" => 200)
      expect(json["data"]).to include("id" => user.id, "email" => user.email)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
    end

    it "sets the HttpOnly jwt cookie used by the web UI" do
      post user_session_path, params: credentials, as: :json

      expect(response.cookies["jwt"]).to be_present
    end

    it "issues a token that authenticates API requests" do
      post user_session_path, params: credentials, as: :json

      get api_v1_employees_path, headers: { "Authorization" => response.headers["Authorization"] }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "rejects a wrong password with 401 and no token" do
      post user_session_path, params: { user: { email: user.email, password: generate(:unused_email) } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Authorization"]).to be_blank
    end

    it "rejects an unknown email with 401" do
      post user_session_path, params: { user: { email: generate(:unused_email), password: user.password } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "accepts JSON posts without a CSRF token, since API clients have none" do
      ActionController::Base.allow_forgery_protection = true

      post user_session_path, params: credentials, as: :json

      expect(response).to have_http_status(:ok)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end
  end

  describe "DELETE /users/sign_out" do
    it "logs out and revokes the token so it can't be reused" do
      headers = auth_headers(user)

      delete destroy_user_session_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("logged out successfully")

      get api_v1_employees_path, headers: headers, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when there is no active session" do
      delete destroy_user_session_path, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["message"]).to eq("Couldn't find an active session.")
    end
  end
end
