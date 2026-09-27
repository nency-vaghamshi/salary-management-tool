# freeze_time / travel_to, for specs that assert on expiry or "now".
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
