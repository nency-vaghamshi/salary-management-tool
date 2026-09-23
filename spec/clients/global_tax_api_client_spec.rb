require "rails_helper"

RSpec.describe GlobalTaxApiClient, type: :model do
  subject(:client) { described_class.new }

  describe "#fetch_countries" do
    it "returns the parsed JSON array from the countries endpoint" do
      stub_request(:get, "https://globaltaxcalculator.net/api/countries")
        .to_return(
          status: 200,
          body: [ { "name" => "India", "code" => "IN" } ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.fetch_countries

      expect(result).to eq([ { "name" => "India", "code" => "IN" } ])
    end

    it "raises Faraday::ResourceNotFound when the endpoint returns a 404" do
      stub_request(:get, "https://globaltaxcalculator.net/api/countries")
        .to_return(status: 404, body: "Not Found")

      expect { client.fetch_countries }.to raise_error(Faraday::ResourceNotFound)
    end

    it "raises Faraday::ServerError when the endpoint returns a 500" do
      stub_request(:get, "https://globaltaxcalculator.net/api/countries")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.fetch_countries }.to raise_error(Faraday::ServerError)
    end
  end

  describe "#fetch_country_tax" do
    it "returns the parsed JSON object from the country-specific endpoint" do
      stub_request(:get, "https://globaltaxcalculator.net/api/countries/IN")
        .to_return(
          status: 200,
          body: { "country" => "India", "countryCode" => "IN", "taxYear" => "2025/26" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.fetch_country_tax("IN")

      expect(result).to eq({ "country" => "India", "countryCode" => "IN", "taxYear" => "2025/26" })
    end

    it "requests the given country code as part of the path" do
      stub = stub_request(:get, "https://globaltaxcalculator.net/api/countries/AE")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      client.fetch_country_tax("AE")

      expect(stub).to have_been_requested
    end

    it "raises Faraday::ResourceNotFound when the country is not found" do
      stub_request(:get, "https://globaltaxcalculator.net/api/countries/ZZ")
        .to_return(status: 404, body: "Not Found")

      expect { client.fetch_country_tax("ZZ") }.to raise_error(Faraday::ResourceNotFound)
    end
  end
end
