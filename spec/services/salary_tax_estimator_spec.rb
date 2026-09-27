require "rails_helper"

RSpec.describe SalaryTaxEstimator do
  let(:country) { create(:country, name: "Testland") }
  let(:salary_record) { create(:salary_record, employment: create(:employment, payroll_country: country)) }

  def add_component(amount, taxable:)
    create(:salary_record_component, salary_record: salary_record, amount: amount,
                                     salary_component: create(:salary_component, is_taxable: taxable))
  end

  def add_tax_configuration(tax_year:, rate:, status: "active")
    create(:tax_configuration, country: country, tax_year: tax_year, status: status).tap do |config|
      create(:tax_bracket, tax_configuration: config, min_income: 0, max_income: nil, tax_rate: rate)
    end
  end

  def estimate
    described_class.new(salary_record.reload).call
  end

  context "with a tax configuration for the payroll country" do
    before do
      add_tax_configuration(tax_year: 2025, rate: 10)
      add_component(100_000, taxable: true)
      add_component(20_000, taxable: false)
    end

    it "taxes only the taxable components" do
      expect(estimate).to have_attributes(gross_amount: 120_000, taxable_income: 100_000, tax_amount: 10_000, error: nil)
    end

    it "takes tax off the full gross to get net pay" do
      expect(estimate.net_amount).to eq(110_000)
    end

    it "includes the bracket breakdown" do
      expect(estimate.breakdown.map(&:rate)).to eq([ 10 ])
    end
  end

  it "uses the latest active tax year, ignoring inactive ones" do
    add_tax_configuration(tax_year: 2024, rate: 5)
    add_tax_configuration(tax_year: 2025, rate: 20)
    add_tax_configuration(tax_year: 2026, rate: 50, status: "inactive")
    add_component(100_000, taxable: true)

    expect(estimate.tax_amount).to eq(20_000)
  end

  it "uses the payroll country, not the employee's nationality or residence" do
    add_tax_configuration(tax_year: 2025, rate: 10)
    salary_record.employment.employee.update!(nationality_country: create(:country), residence_country: create(:country))
    add_component(100_000, taxable: true)

    expect(estimate.tax_amount).to eq(10_000)
  end

  it "returns an error, not an exception, when the country has no tax configuration" do
    add_component(100_000, taxable: true)

    expect(estimate).to have_attributes(error: "No tax configuration found for Testland", tax_amount: nil, net_amount: nil,
                                        gross_amount: 100_000, breakdown: [])
  end

  it "returns an error when the tax configuration has no brackets" do
    create(:tax_configuration, country: country, tax_year: 2025)
    add_component(100_000, taxable: true)

    expect(estimate.error).to eq("No tax brackets configured for Testland (2025)")
  end
end
