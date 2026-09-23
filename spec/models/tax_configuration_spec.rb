require "rails_helper"

RSpec.describe TaxConfiguration, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:tax_configuration)).to be_valid
  end

  it "is invalid without a country" do
    tax_configuration = build_stubbed(:tax_configuration, country: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:country]).to include("must exist")
  end

  it "is invalid without a tax_year" do
    tax_configuration = build_stubbed(:tax_configuration, tax_year: nil)

    expect(tax_configuration).not_to be_valid
    expect(tax_configuration.errors[:tax_year]).to include("can't be blank")
  end

  it "is invalid with a duplicate tax_year for the same country" do
    country = create(:country, :india)
    create(:tax_configuration, country: country, tax_year: 2025)
    duplicate = build(:tax_configuration, country: country, tax_year: 2025)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:tax_year]).to include("has already been taken")
  end

  it "is valid with the same tax_year for a different country" do
    create(:tax_configuration, country: create(:country, :india), tax_year: 2025)
    other_config = build_stubbed(:tax_configuration, country: build_stubbed(:country, :united_states), tax_year: 2025)

    expect(other_config).to be_valid
  end

  it "defaults to the active status" do
    expect(TaxConfiguration.new.status).to eq("active")
  end

  it "rejects a status outside the defined set" do
    expect { build_stubbed(:tax_configuration, status: "pending") }.to raise_error(ArgumentError)
  end

  it "has many tax_brackets" do
    tax_configuration = create(:tax_configuration)
    bracket = create(:tax_bracket, tax_configuration: tax_configuration)

    expect(tax_configuration.tax_brackets).to include(bracket)
  end

  it "destroys dependent tax_brackets when destroyed" do
    tax_configuration = create(:tax_configuration)
    bracket = create(:tax_bracket, tax_configuration: tax_configuration)

    tax_configuration.destroy!

    expect(TaxBracket.exists?(bracket.id)).to be false
  end
end
