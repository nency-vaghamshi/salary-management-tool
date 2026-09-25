#!/usr/bin/env bash
set -o errexit
bundle install
bundle exec rails tailwindcss:build
# tailwindcss-rails hooks tailwindcss:build into assets:precompile.
bundle exec rails assets:precompile
bundle exec rails assets:clean

bundle exec rails db:migrate

# Solid Queue/Cache/Cable ship as schema files, not migrations, so db:migrate
# never creates their tables. On Render they share DATABASE_URL with primary,
# and the schema files use force: :cascade, so each one is loaded only while
# its tables are missing; reloading would wipe pending jobs and cache.
bundle exec rails runner '
  { "solid_queue_jobs" => "queue", "solid_cache_entries" => "cache", "solid_cable_messages" => "cable" }.each do |table, schema|
    next if ActiveRecord::Base.connection.table_exists?(table)

    puts "Loading db/#{schema}_schema.rb"
    load Rails.root.join("db/#{schema}_schema.rb")
  end
'

# Both are safe to rerun on every deploy: db:seed skips data that already
# exists, and seed_employees only tops up to 10,000.
bundle exec rails db:seed
bundle exec rails db:seed_employees
