require "rails_helper"

RSpec.describe "Password reset", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/password/new" do
    it "renders the forgot-password page without requiring a token" do
      get new_user_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/password" do
    it "emails reset instructions and sends the user back to login" do
      expect {
        post user_password_path, params: { user: { email: user.email } }
      }.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(ActionMailer::Base.deliveries.last.to).to eq([ user.email ])
      expect(response).to redirect_to(login_path)
    end

    it "responds the same way for an unknown email, so accounts can't be discovered" do
      expect {
        post user_password_path, params: { user: { email: "nobody@example.com" } }
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(login_path)
    end
  end

  describe "PUT /users/password" do
    it "changes the password with a valid reset token and sends the user to login" do
      token = user.send_reset_password_instructions

      put user_password_path, params: { user: { reset_password_token: token, password: "NewPass456!", password_confirmation: "NewPass456!" } }

      expect(response).to redirect_to(login_path)
      expect(user.reload.valid_password?("NewPass456!")).to be(true)
    end

    it "rejects an invalid reset token and keeps the old password" do
      put user_password_path, params: { user: { reset_password_token: "wrong", password: "NewPass456!", password_confirmation: "NewPass456!" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.valid_password?("SecurePass123!")).to be(true)
    end
  end
end
