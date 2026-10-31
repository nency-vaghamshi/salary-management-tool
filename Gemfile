source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Utility for readable console output
gem "awesome_print"

# Static analysis for security vulnerabilities [https://brakemanscanner.org/]
gem "brakeman", require: false

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Flags N+1 queries and unused eager loading [https://github.com/flyerhzm/bullet]
gem "bullet"

# Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
gem "capybara"

# See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

# Flexible authentication solution for the User model [https://github.com/heartcombo/devise]
gem "devise"

gem "devise"

gem "devise-jwt"

# Fixtures replacement with a straightforward definition syntax [https://github.com/thoughtbot/factory_bot_rails]
gem "factory_bot_rails"

# Generates realistic fake data for seeding (names, emails, etc.) [https://github.com/faker-ruby/faker]
gem "faker"

gem "faraday"
gem "faraday-retry"

# Keeps Postgres functions/triggers in schema.rb (db/functions, db/triggers) [https://github.com/teoljungberg/fx]
gem "fx"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Pin below 3.0: pg 1.6's jsonb encoder passes a `quirks_mode:` keyword that
# the json gem removed in 3.0, breaking any jsonb column write (see AuditLog).
gem "json", "~> 2.9"

# Encode/decode JSON Web Tokens for the API's bearer authentication [https://github.com/jwt/ruby-jwt]
gem "jwt"

gem "jsonapi-serializer"

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# UI for the active job
gem "mission_control-jobs"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Lightweight, database-friendly pagination for the employee roster (10k+ rows) [https://github.com/ddnexus/pagy]
gem "pagy", "~> 9.3"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.7"

gem "pry-rails"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.5", ">= 8.0.5.1"

gem "rails-local-ci"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem "rspec-rails"

gem "rack-cors"

# Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
gem "selenium-webdriver"

# Test coverage report in coverage/index.html [https://github.com/simplecov-ruby/simplecov]
gem "simplecov", require: false

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_cable"
gem "solid_queue"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_queue"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cable"

# Use the standalone Tailwind CLI, no Node required [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Stubs HTTP requests in specs so external API clients are tested without
# real network calls [https://github.com/bblimke/webmock]
gem "webmock"

group :development, :test do
  gem "brakeman", require: false
  gem "bullet"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "awesome_print"
  gem "rails-local-ci"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webmock"
end
gem "omniauth-google-oauth2", "~> 1.2"
gem "omniauth-rails_csrf_protection", "~> 2.0"
