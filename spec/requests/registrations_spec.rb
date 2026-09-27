require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /register" do
    it "renders the sign-up page without requiring a token" do
      get register_path

      expect(response).to have_http_status(:ok)
    end
  end
end
