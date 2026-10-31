# The Google provider is registered through Devise (config.omniauth in
# devise.rb) so its callback routes exist; registering it here as well would
# add the middleware twice.
# POST only, paired with omniauth-rails_csrf_protection, to prevent login CSRF.
OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.full_host = Rails.env.production? ? "https://your-domain.com" : "http://localhost:3000"
