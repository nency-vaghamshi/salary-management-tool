require "rails_helper"

RSpec.describe TaxDataImporter, type: :model do
  let(:client) { instance_double(GlobalTaxApiClient) }

  subject(:importer) { described_class.new(client) }

  def india_tax_data(tax_year: "2025/26")
    {
      "country" => "India",
      "countryCode" => "IN",
      "taxYear" => tax_year,
      "currency" => "INR",
      "incomeTax" => {
        "brackets" => [
          { "lowerLimit" => 0, "upperLimit" => 250_000, "rate" => 0.0 },
          { "lowerLimit" => 250_000, "upperLimit" => nil, "rate" => 0.05 }
        ]
      }
    }
  end

  describe "#call" do
    it "imports a country's tax data into Country, Currency, TaxConfiguration, and TaxBracket" do
      allow(client).to receive(:fetch_countries).and_return([ { "name" => "India", "code" => "IN" } ])
      allow(client).to receive(:fetch_country_tax).with("IN").and_return(india_tax_data)

      result = importer.call

      expect(result.imported).to eq([ "IN" ])
      expect(result.failed).to be_empty

      country = Country.find_by(code: "IN")
      expect(country.name).to eq("India")
      expect(country.currency.code).to eq("INR")

      tax_configuration = country.tax_configurations.sole
      expect(tax_configuration.tax_year).to eq(2025)
      expect(tax_configuration.tax_brackets.order(:min_income).pluck(:tax_rate)).to eq([ 0.0, 5.0 ])
    end

    it "parses a fiscal-year range taxYear using its starting year" do
      allow(client).to receive(:fetch_countries).and_return([ { "name" => "India", "code" => "IN" } ])
      allow(client).to receive(:fetch_country_tax).with("IN").and_return(india_tax_data(tax_year: "2025/26"))

      importer.call

      expect(TaxConfiguration.sole.tax_year).to eq(2025)
    end

    it "raises when a country entry has a blank code" do
      allow(client).to receive(:fetch_countries).and_return([ { "name" => "Unknown", "code" => "" } ])

      expect { importer.call }.to raise_error(ArgumentError, /Missing country code/)
    end

    it "raises when the countries response is not an array" do
      allow(client).to receive(:fetch_countries).and_return({ "error" => "bad response" })

      expect { importer.call }.to raise_error(ArgumentError, /expected an array/)
    end

    it "raises when a country entry is missing a code key entirely" do
      allow(client).to receive(:fetch_countries).and_return([ { "name" => "India" } ])

      expect { importer.call }.to raise_error(ArgumentError, /Missing country code/)
    end

    it "records a per-country failure without aborting the rest of the batch" do
      allow(client).to receive(:fetch_countries).and_return([
        { "name" => "India", "code" => "IN" },
        { "name" => "Germany", "code" => "DE" }
      ])
      allow(client).to receive(:fetch_country_tax).with("IN").and_return(india_tax_data)
      allow(client).to receive(:fetch_country_tax).with("DE").and_raise(Faraday::ResourceNotFound.new("not found"))

      result = importer.call

      expect(result.imported).to eq([ "IN" ])
      expect(result.failed).to eq([ { code: "DE", error: "not found" } ])
      expect(Country.exists?(code: "IN")).to be true
      expect(Country.exists?(code: "DE")).to be false
    end

    it "records a failure when a tax bracket is missing its rate" do
      allow(client).to receive(:fetch_countries).and_return([ { "name" => "India", "code" => "IN" } ])
      broken_data = india_tax_data
      broken_data["incomeTax"]["brackets"][0].delete("rate")
      allow(client).to receive(:fetch_country_tax).with("IN").and_return(broken_data)

      result = importer.call

      expect(result.imported).to be_empty
      expect(result.failed.first[:code]).to eq("IN")
      expect(result.failed.first[:error]).to match(/Missing rate in bracket 0/)
    end

    it "is idempotent: re-running replaces brackets instead of duplicating them" do
      allow(client).to receive(:fetch_countries).and_return([ { "name" => "India", "code" => "IN" } ])
      allow(client).to receive(:fetch_country_tax).with("IN").and_return(india_tax_data)

      importer.call
      importer.call

      expect(Country.where(code: "IN").count).to eq(1)
      expect(TaxConfiguration.where(country: Country.find_by(code: "IN"), tax_year: 2025).count).to eq(1)
      expect(TaxBracket.count).to eq(2)
    end

    it "reuses an existing currency across countries" do
      allow(client).to receive(:fetch_countries).and_return([
        { "name" => "India", "code" => "IN" },
        { "name" => "Bhutan", "code" => "BT" }
      ])
      allow(client).to receive(:fetch_country_tax).with("IN").and_return(india_tax_data)
      allow(client).to receive(:fetch_country_tax).with("BT").and_return(india_tax_data.merge("country" => "Bhutan", "countryCode" => "BT"))

      importer.call

      expect(Currency.where(code: "INR").count).to eq(1)
    end
  end
end
