# Request specs sign in the way the app does: a devise-jwt token, sent as a Bearer header
# (the API's way; the web pages accept it too, alongside the signed cookie).
module AuthHelpers
  def auth_headers(user = create(:user))
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}" }
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
