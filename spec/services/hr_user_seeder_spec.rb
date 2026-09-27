require "rails_helper"

RSpec.describe HrUserSeeder do
  describe ".call" do
    it "creates the default HR login" do
      user = described_class.call

      expect(user).to be_persisted
      expect(user.email).to eq(described_class::DEFAULT_EMAIL)
      expect(user.valid_password?(described_class::DEFAULT_PASSWORD)).to be(true)
      expect(user).to be_hr_manager
    end

    it "is idempotent" do
      described_class.call

      expect { described_class.call }.not_to change(User, :count)
    end

    it "does not reset the password of an existing HR user" do
      create(:user, email: described_class::DEFAULT_EMAIL, password: "ChangedPass789!")

      described_class.call

      expect(User.find_by(email: described_class::DEFAULT_EMAIL).valid_password?("ChangedPass789!")).to be(true)
    end
  end
end
