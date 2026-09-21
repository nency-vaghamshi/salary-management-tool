require "rails_helper"

RSpec.describe Currency, type: :model do
  subject(:currency) { described_class.new(code: "INR", name: "Indian Rupee", symbol: "₹") }

  it "is valid with a code, name, and symbol" do
    expect(currency).to be_valid
  end

  it "is invalid without a code" do
    currency.code = nil

    expect(currency).not_to be_valid
    expect(currency.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    described_class.create!(code: "INR", name: "Indian Rupee", symbol: "₹")
    currency.name = "Indian Rupee Duplicate"

    expect(currency).not_to be_valid
    expect(currency.errors[:code]).to include("has already been taken")
  end

  it "is invalid without a name" do
    currency.name = nil

    expect(currency).not_to be_valid
    expect(currency.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a symbol" do
    currency.symbol = nil

    expect(currency).not_to be_valid
    expect(currency.errors[:symbol]).to include("can't be blank")
  end
end
