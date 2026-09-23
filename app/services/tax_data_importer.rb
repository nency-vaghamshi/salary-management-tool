# app/services/tax_data_importer.rb
require "benchmark"

class TaxDataImporter
  # Structural DTO definitions embedded directly inside the service domain
  TaxCountryData = Data.define(:code, :fallback_name, :country_name, :tax_year, :currency, :brackets)
  TaxBracketData = Data.define(:min_income, :max_income, :tax_rate)
  Result         = Data.define(:imported, :failed)

  def initialize(client = GlobalTaxApiClient.new)
    @client = client
  end

  def call
    imported = []
    failed = []

    time = Benchmark.realtime do
      raw_countries = @client.fetch_countries
      validate_countries_response!(raw_countries)

      raw_countries.each do |country_payload|
        code = country_payload["code"].to_s.strip.upcase
        fallback_name = country_payload["name"].to_s.strip

        next if code.blank?

        begin
          import_country(code, fallback_name: fallback_name)
          imported << code
        rescue StandardError => e
          Rails.logger.error("Tax import failed for #{code}: #{e.class}: #{e.message}")
          failed << { code: code, error: e.message }
        end
      end
    end

    Rails.logger.info "⏱️ TaxDataImporter took #{time.round(2)}s to execute."
    # Correctly returned at the very end of the method execution
    Result.new(imported: imported, failed: failed)
  end

  private

  def import_country(code, fallback_name:)
    # 1. Fetch raw payload purely in memory via Faraday client
    raw_data = @client.fetch_country_tax(code)
    # 2. Map and validate properties directly into local Data Objects
    country_data = parse_and_validate_tax_data!(raw_data, code, fallback_name)

    # 3. Transaction boundary ensures atomicity per country
    ActiveRecord::Base.transaction(requires_new: true) do
      currency = Currency.find_or_create_by!(code: country_data.currency) do |curr|
        curr.name = country_data.currency
        curr.symbol = country_data.currency
      end

      country = Country.find_or_initialize_by(code: country_data.code)
      if country.new_record?
        country.name = country_data.country_name
        country.currency = currency
        country.save!
      end

      tax_configuration = TaxConfiguration.find_or_create_by!(
        country: country,
        tax_year: country_data.tax_year
      ) do |config|
        config.status = "active"
      end

      # Safely drops old brackets within the transaction block so re-imports
      # stay idempotent; skipped for a config just created this run, where
      # there's nothing yet to clear.
      tax_configuration.tax_brackets.delete_all unless tax_configuration.previously_new_record?

      # Prepare properties for structural single-query bulk import
      bracket_attributes = country_data.brackets.map do |bracket|
        {
          tax_configuration_id: tax_configuration.id,
          min_income: bracket.min_income,
          max_income: bracket.max_income,
          tax_rate: bracket.tax_rate,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Optimizes memory allocation and minimizes database IO roundtrips
      TaxBracket.insert_all!(bracket_attributes) if bracket_attributes.any?
    end
  end

  # --------------------------------------------------------------------------
  # PAYLOAD VALIDATION & PARSING
  # --------------------------------------------------------------------------

  def validate_countries_response!(countries)
    raise ArgumentError, "Invalid countries response: expected an array" unless countries.is_a?(Array)

    countries.each_with_index do |country, index|
      raise ArgumentError, "Invalid country at index #{index}: expected an object" unless country.is_a?(Hash)
      raise ArgumentError, "Missing country code at index #{index}" if country["code"].blank?
    end
  end

  def parse_and_validate_tax_data!(raw_data, code, fallback_name)
    raise ArgumentError, "Invalid tax response for #{code}: expected an object" unless raw_data.is_a?(Hash)
    tax_year = parse_tax_year(raw_data["taxYear"])
    raise ArgumentError, "Missing or invalid taxYear in response for #{code}" if tax_year.nil?

    currency = raw_data["currency"].to_s.strip.upcase
    raise ArgumentError, "Missing currency in response for #{code}" if currency.blank?

    raw_brackets = raw_data.dig("incomeTax", "brackets")
    raise ArgumentError, "Missing or invalid incomeTax.brackets for #{code}" unless raw_brackets.is_a?(Array)

    parsed_brackets = raw_brackets.map.with_index do |bracket, index|
      validate_and_parse_bracket!(bracket, code, index)
    end

    TaxCountryData.new(
      code: code,
      fallback_name: fallback_name,
      country_name: raw_data["country"].presence || fallback_name,
      tax_year: tax_year,
      currency: currency,
      brackets: parsed_brackets
    )
  end

  def parse_tax_year(raw_value)
    match = raw_value.to_s.match(/\A(\d{4})/)
    match && match[1].to_i
  end

  def validate_and_parse_bracket!(bracket, code, index)
    raise ArgumentError, "Invalid tax bracket #{index} for #{code}" unless bracket.is_a?(Hash)
    raise ArgumentError, "Missing lowerLimit in bracket #{index} for #{code}" if bracket["lowerLimit"].nil?
    raise ArgumentError, "Missing rate in bracket #{index} for #{code}" if bracket["rate"].nil?

    rate = Float(bracket["rate"], exception: false)
    raise ArgumentError, "Invalid rate in bracket #{index} for #{code}" if rate.nil?
    raise ArgumentError, "Negative tax rate in bracket #{index} for #{code}" if rate.negative?

    upper_limit = nil
    if bracket["upperLimit"].present?
      upper_limit = Float(bracket["upperLimit"], exception: false)
      raise ArgumentError, "Invalid upperLimit in bracket #{index} for #{code}" if upper_limit.nil?
    end

    TaxBracketData.new(
      min_income: bracket["lowerLimit"],
      max_income: upper_limit,
      tax_rate: rate * 100
    )
  end
end
