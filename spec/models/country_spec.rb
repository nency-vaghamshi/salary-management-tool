require "rails_helper"

RSpec.describe Country, type: :model do
  it "is valid with a name, code, and currency" do
    expect(build_stubbed(:country)).to be_valid
  end

  it "is invalid without a name" do
    country = build_stubbed(:country, name: nil)

    expect(country).not_to be_valid
    expect(country.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    country = build_stubbed(:country, code: nil)

    expect(country).not_to be_valid
    expect(country.errors[:code]).to include("can't be blank")
  end

  it "is invalid without a currency" do
    country = build_stubbed(:country, currency: nil)

    expect(country).not_to be_valid
    expect(country.errors[:currency]).to include("must exist")
  end

  it "is invalid with a duplicate code" do
    create(:country, code: "US")
    duplicate = build(:country, code: "US")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end

  it "has many tax_configurations" do
    country = create(:country, :india)
    tax_configuration = create(:tax_configuration, country: country)

    expect(country.tax_configurations).to include(tax_configuration)
  end

  it "destroys dependent tax_configurations when destroyed" do
    country = create(:country, :india)
    tax_configuration = create(:tax_configuration, country: country)

    country.destroy!

    expect(TaxConfiguration.exists?(tax_configuration.id)).to be false
  end
end
