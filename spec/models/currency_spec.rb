require "rails_helper"

RSpec.describe Currency, type: :model do
  it "is valid with a code, name, and symbol" do
    currency = Currency.new(code: "USD", name: "US Dollar", symbol: "$")

    expect(currency).to be_valid
  end

  it "is invalid without a code" do
    currency = Currency.new(code: nil, name: "US Dollar", symbol: "$")

    expect(currency).not_to be_valid
    expect(currency.errors[:code]).to include("can't be blank")
  end

  it "is invalid without a name" do
    currency = Currency.new(code: "USD", name: nil, symbol: "$")

    expect(currency).not_to be_valid
    expect(currency.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a symbol" do
    currency = Currency.new(code: "USD", name: "US Dollar", symbol: nil)

    expect(currency).not_to be_valid
    expect(currency.errors[:symbol]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    Currency.create!(code: "USD", name: "US Dollar", symbol: "$")
    duplicate = Currency.new(code: "USD", name: "US Dollar Duplicate", symbol: "$")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end
end
