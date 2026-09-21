require "rails_helper"

RSpec.describe TaxConfiguration, type: :model do
  let(:currency) { Currency.create!(code: "INR", name: "Indian Rupee", symbol: "₹") }
  let(:country) { Country.create!(name: "India", code: "IN", currency: currency) }

  def build_tax_configuration(attributes = {})
    TaxConfiguration.new(
      {
        country: country,
        name: "India Income Tax",
        tax_type: "income_tax",
        calculation_method: "progressive",
        rate: 18.5,
        threshold_amount: 250_000.00,
        effective_from: Date.new(2026, 4, 1),
        effective_to: nil
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_tax_configuration).to be_valid
  end

  it "is invalid without a country" do
    tax_configuration = build_tax_configuration(country: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:country]).to include("must exist")
  end

  it "is invalid without a name" do
    tax_configuration = build_tax_configuration(name: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a tax_type" do
    tax_configuration = build_tax_configuration(tax_type: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:tax_type]).to include("can't be blank")
  end

  it "is invalid without a calculation_method" do
    tax_configuration = build_tax_configuration(calculation_method: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:calculation_method]).to include("can't be blank")
  end

  it "is invalid without an effective_from date" do
    tax_configuration = build_tax_configuration(effective_from: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:effective_from]).to include("can't be blank")
  end

  it "is valid without a rate or threshold_amount" do
    tax_configuration = build_tax_configuration(rate: nil, threshold_amount: nil)

    expect(tax_configuration).to be_valid
  end
end
