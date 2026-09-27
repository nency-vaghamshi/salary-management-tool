require "rails_helper"

# Pure math over in-memory brackets: nothing here touches the database.
RSpec.describe TaxCalculator do
  # 0–10k at 0%, 10k–50k at 10%, 50k+ at 30%
  let(:tax_configuration) do
    build(:tax_configuration, country: build(:country, name: "Testland"), tax_year: 2025).tap do |config|
      config.tax_brackets.build(min_income: 0, max_income: 10_000, tax_rate: 0)
      config.tax_brackets.build(min_income: 10_000, max_income: 50_000, tax_rate: 10)
      config.tax_brackets.build(min_income: 50_000, max_income: nil, tax_rate: 30)
    end
  end

  def tax_on(income, configuration: tax_configuration)
    described_class.new(tax_configuration: configuration, taxable_income: income).call
  end

  it "taxes only the slice of income that falls in each bracket" do
    # 0 on the first 10k, 10% of 40k = 4,000, 30% of 20k = 6,000
    expect(tax_on(70_000).tax_amount).to eq(10_000)
  end

  it "stops at the bracket the income ends in" do
    result = tax_on(30_000)

    expect(result.tax_amount).to eq(2_000)
    expect(result.breakdown.map(&:rate)).to eq([ 0, 10 ])
  end

  it "is exact on a bracket boundary" do
    expect(tax_on(50_000).tax_amount).to eq(4_000)
  end

  it "applies the open-ended top bracket to everything above its minimum" do
    expect(tax_on(1_050_000).tax_amount).to eq(4_000 + 300_000)
  end

  it "returns a per-bracket breakdown that adds up to the total" do
    result = tax_on(70_000)

    expect(result.breakdown.map { |b| [ b.min_income, b.max_income, b.taxable_amount, b.tax ] }).to eq([
      [ 0, 10_000, 10_000, 0 ],
      [ 10_000, 50_000, 40_000, 4_000 ],
      [ 50_000, nil, 20_000, 6_000 ]
    ])
    expect(result.breakdown.sum(&:tax)).to eq(result.tax_amount)
  end

  it "sorts brackets by min_income, whatever order they were stored in" do
    shuffled = build(:tax_configuration).tap do |config|
      config.tax_brackets.build(min_income: 50_000, max_income: nil, tax_rate: 30)
      config.tax_brackets.build(min_income: 0, max_income: 50_000, tax_rate: 10)
    end

    expect(tax_on(60_000, configuration: shuffled).tax_amount).to eq(5_000 + 3_000)
  end

  it "rounds each bracket's tax to cents" do
    flat = build(:tax_configuration).tap { |config| config.tax_brackets.build(min_income: 0, max_income: nil, tax_rate: 3.333) }

    expect(tax_on(100.01, configuration: flat).tax_amount).to eq(BigDecimal("3.33"))
  end

  it "charges no tax on zero income" do
    result = tax_on(0)

    expect(result.tax_amount).to eq(0)
    expect(result.breakdown).to be_empty
  end

  it "charges no tax on negative income" do
    expect(tax_on(-500).tax_amount).to eq(0)
  end

  it "accepts income as a string or integer and returns BigDecimal" do
    expect(tax_on("70000").tax_amount).to be_a(BigDecimal).and eq(10_000)
  end

  it "raises when the configuration has no brackets" do
    empty = build(:tax_configuration, country: build(:country, name: "Testland"), tax_year: 2025)

    expect { tax_on(1_000, configuration: empty) }
      .to raise_error(described_class::MissingTaxBracketsError, "No tax brackets configured for Testland (2025)")
  end
end
