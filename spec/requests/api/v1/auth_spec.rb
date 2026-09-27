require "rails_helper"

RSpec.describe "API v1 auth", type: :request do
  describe "POST /api/v1/auth/signup" do
    let(:params) { { name: "Grace Hopper", email: "grace@example.com", password: "SecurePass123!", password_confirmation: "SecurePass123!" } }

    it "creates the user and returns a token plus a signed cookie" do
      expect { post api_v1_auth_signup_path, params: params, as: :json }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["token"]).to be_present
      expect(json["user"]).to include("name" => "Grace Hopper", "email" => "grace@example.com")
      expect(response.cookies["jwt"]).to be_present
    end

    it "keeps the default role even when the client asks for another one" do
      post api_v1_auth_signup_path, params: params.merge(role: "admin"), as: :json

      expect(User.last).to be_hr_manager
    end

    it "returns 422 with the validation errors" do
      post api_v1_auth_signup_path, params: params.merge(email: ""), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("Email can't be blank")
    end

    it "accepts JSON posts without a CSRF token, since API clients have none" do
      ActionController::Base.allow_forgery_protection = true

      post api_v1_auth_signup_path, params: params, as: :json

      expect(response).to have_http_status(:created)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end
  end

  describe "POST /api/v1/auth/login" do
    let(:user) { create(:user) }

    it "returns a token that authenticates later requests" do
      post api_v1_auth_login_path, params: { email: user.email, password: "SecurePass123!" }, as: :json

      expect(response).to have_http_status(:ok)
      get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{json['token']}" }, as: :json
      expect(json["user"]["id"]).to eq(user.id)
    end

    it "returns 401 for a wrong password" do
      post api_v1_auth_login_path, params: { email: user.email, password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("error" => "Invalid email or password")
    end

    it "returns the same 401 for an unknown email, so accounts can't be discovered" do
      post api_v1_auth_login_path, params: { email: "nobody@example.com", password: "SecurePass123!" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("error" => "Invalid email or password")
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "clears the cookie so the browser is signed out" do
      post api_v1_auth_login_path, params: { email: create(:user).email, password: "SecurePass123!" }, as: :json

      delete api_v1_auth_logout_path, as: :json

      expect(response).to have_http_status(:no_content)
      get employees_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the signed-in user" do
      user = create(:user)

      get api_v1_auth_me_path, headers: auth_headers(user), as: :json

      expect(json["user"]).to eq("id" => user.id, "name" => user.name, "email" => user.email)
    end

    it "returns 401 without a token" do
      get api_v1_auth_me_path, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
