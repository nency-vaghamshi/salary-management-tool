# Request specs sign in the way the app does: a JWT, sent as a Bearer header
# (the API's way; the web pages accept it too, alongside the signed cookie).
module AuthHelpers
  def auth_headers(user = create(:user))
    { "Authorization" => "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
