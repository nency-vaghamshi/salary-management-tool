require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:user)).to be_valid
  end

  it "is invalid without a name" do
    user = build_stubbed(:user, name: nil)

    expect(user).not_to be_valid
    expect(user.errors[:name]).to include("can't be blank")
  end

  it "is invalid without an email" do
    user = build_stubbed(:user, email: nil)

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it "is invalid without a password on signup" do
    user = User.new(name: "Grace Hopper", email: "hr@example.com")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("can't be blank")
  end

  it "authenticates with the correct password" do
    user = create(:user, password: "SecurePass123!")

    expect(user.valid_password?("SecurePass123!")).to eq(true)
  end

  it "does not authenticate with an incorrect password" do
    user = create(:user, password: "SecurePass123!")

    expect(user.valid_password?("wrong-password")).to eq(false)
  end

  it "is invalid with a duplicate email" do
    create(:user, email: "hr@example.com")
    duplicate = build(:user, email: "hr@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "defaults to the hr_manager role" do
    expect(User.new.role).to eq("hr_manager")
  end

  it "rejects a role outside the defined set" do
    expect { build_stubbed(:user, role: "super_admin") }.to raise_error(ArgumentError)
  end
end
