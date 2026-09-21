require "rails_helper"

RSpec.describe Country, type: :model do
  let(:currency) { Currency.create!(code: "INR", name: "Indian Rupee", symbol: "₹") }
  subject(:country) { described_class.new(name: "India", code: "IN", currency: currency) }

  it "is valid with a name, code, and currency" do
    expect(country).to be_valid
  end

  it "is invalid without a name" do
    country.name = nil

    expect(country).not_to be_valid
    expect(country.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    country.code = nil

    expect(country).not_to be_valid
    expect(country.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    described_class.create!(name: "India", code: "IN", currency: currency)
    country.name = "India Duplicate"

    expect(country).not_to be_valid
    expect(country.errors[:code]).to include("has already been taken")
  end

  it "is invalid without a currency" do
    country.currency = nil

    expect(country).not_to be_valid
    expect(country.errors[:currency]).to include("must exist")
  end
end
