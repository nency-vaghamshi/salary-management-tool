# app/clients/global_tax_api_client.rb
class GlobalTaxApiClient
  BASE_URL = "https://globaltaxcalculator.net/api/".freeze
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30
  MAX_RETRIES = 3

  def fetch_countries
    response = connection.get("countries")
    response.body
  end

  def fetch_country_tax(code)
    response = connection.get("countries/#{code}")
    response.body
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.options.open_timeout = OPEN_TIMEOUT
      f.options.timeout = READ_TIMEOUT

      # Gracefully retries network stutters with an exponential backoff
      f.request :retry,
                max: MAX_RETRIES,
                interval: 2,
                backoff_factor: 2,
                exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS

      f.request :json
      f.response :json
      f.response :raise_error # Maps 4xx/5xx responses to Faraday::Error exceptions
    end
  end
end
