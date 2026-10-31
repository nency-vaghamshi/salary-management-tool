require "rails_helper"

RSpec.describe "Registrations API", type: :request do
  let(:attributes) { attributes_for(:user).slice(:name, :email, :password) }
  let(:params) { { user: attributes.merge(password_confirmation: attributes[:password]) } }

  describe "POST /users" do
    it "creates the user and returns a bearer token" do
      expect { post user_registration_path, params: params, as: :json }.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to include("email" => attributes[:email])
      expect(User.last.name).to eq(attributes[:name])
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(response.cookies["jwt"]).to be_present
    end

    it "defaults new users to the hr_manager role" do
      post user_registration_path, params: params, as: :json

      expect(User.last).to be_hr_manager
    end

    it "returns 422 with the reason when the email is missing" do
      params[:user][:email] = ""

      expect { post user_registration_path, params: params, as: :json }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["status"]["message"]).to include("Email can't be blank")
    end

    it "returns 422 when the password confirmation doesn't match" do
      params[:user][:password_confirmation] = generate(:unused_email)

      post user_registration_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["status"]["message"]).to include("Password confirmation doesn't match")
    end

    it "returns 422 when the name is missing" do
      params[:user][:name] = ""

      post user_registration_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["status"]["message"]).to include("Name can't be blank")
    end

    it "returns 422 for an email that is already taken" do
      create(:user, email: attributes[:email])

      post user_registration_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["status"]["message"]).to include("Email has already been taken")
    end
  end

  describe "PATCH /users" do
    let(:user) { create(:user) }
    let(:new_name) { generate(:person_name) }

    it "updates the account when the current password is given" do
      patch user_registration_path, params: { user: { name: new_name, current_password: user.password } },
                                    headers: auth_headers(user), as: :json

      expect(user.reload.name).to eq(new_name)
    end

    it "does not update without the current password" do
      original_name = user.name

      patch user_registration_path, params: { user: { name: new_name } }, headers: auth_headers(user), as: :json

      expect(user.reload.name).to eq(original_name)
    end

    it "requires authentication" do
      patch user_registration_path, params: { user: { name: new_name } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /users" do
    it "deletes the signed-in account" do
      user = create(:user)

      expect { delete user_registration_path, headers: auth_headers(user), as: :json }.to change(User, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json["status"]["message"]).to eq("Account deleted successfully.")
    end

    it "requires authentication" do
      create(:user)

      expect { delete user_registration_path, as: :json }.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
