class JsonWebToken
  ALGORITHM = "HS256".freeze

  def self.encode(payload, exp: 24.hours.from_now)
    payload = payload.merge(exp: exp.to_i)
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM).first
    decoded.symbolize_keys
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
end
