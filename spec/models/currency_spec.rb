require "rails_helper"

RSpec.describe Currency, type: :model do
  it "is valid with a code, name, and symbol" do
    expect(build_stubbed(:currency)).to be_valid
  end

  it "is invalid without a code" do
    currency = build_stubbed(:currency, code: nil)

    expect(currency).not_to be_valid
    expect(currency.errors[:code]).to include("can't be blank")
  end

  it "is invalid without a name" do
    currency = build_stubbed(:currency, name: nil)

    expect(currency).not_to be_valid
    expect(currency.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a symbol" do
    currency = build_stubbed(:currency, symbol: nil)

    expect(currency).not_to be_valid
    expect(currency.errors[:symbol]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    create(:currency, code: "USD")
    duplicate = build(:currency, code: "USD")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end
end
