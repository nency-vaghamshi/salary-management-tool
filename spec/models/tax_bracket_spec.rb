require "rails_helper"

RSpec.describe TaxBracket, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:tax_bracket)).to be_valid
  end

  it "is invalid without a tax_configuration" do
    bracket = build_stubbed(:tax_bracket, tax_configuration: nil)

    expect(bracket).not_to be_valid
    expect(bracket.errors[:tax_configuration]).to include("must exist")
  end

  it "is invalid without a min_income" do
    bracket = build_stubbed(:tax_bracket, min_income: nil)

    expect(bracket).not_to be_valid
    expect(bracket.errors[:min_income]).to include("can't be blank")
  end

  it "is invalid with a negative min_income" do
    bracket = build_stubbed(:tax_bracket, min_income: -1)

    expect(bracket).not_to be_valid
    expect(bracket.errors[:min_income]).to include("must be greater than or equal to 0")
  end

  it "is valid with a nil max_income, representing no upper limit" do
    expect(build_stubbed(:tax_bracket, max_income: nil)).to be_valid
  end

  it "is invalid when max_income is not greater than min_income" do
    bracket = build_stubbed(:tax_bracket, min_income: 250_000, max_income: 250_000)

    expect(bracket).not_to be_valid
    expect(bracket.errors[:max_income]).to include("must be greater than 250000.0")
  end

  it "is invalid without a tax_rate" do
    bracket = build_stubbed(:tax_bracket, tax_rate: nil)

    expect(bracket).not_to be_valid
    expect(bracket.errors[:tax_rate]).to include("can't be blank")
  end

  it "is invalid with a negative tax_rate" do
    bracket = build_stubbed(:tax_bracket, tax_rate: -5)

    expect(bracket).not_to be_valid
    expect(bracket.errors[:tax_rate]).to include("must be greater than or equal to 0")
  end

  it "is valid with a zero tax_rate, representing a tax-free bracket" do
    expect(build_stubbed(:tax_bracket, tax_rate: 0)).to be_valid
  end
end
