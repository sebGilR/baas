# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> 3.4.0"

# Rails & Core
gem "pg", "~> 1.5"
gem "puma", "~> 7.1"
gem "rails", "~> 8.0.0"

# API & Serialization
gem "jsonapi-serializer", "~> 2.2"
gem "pundit", "~> 2.3"

# Multi-Tenancy
gem "acts_as_tenant", "~> 1.0"

# Authentication & Authorization
gem "bcrypt", "~> 3.1"
gem "jwt", "~> 3.1"

# Background Jobs
gem "solid_queue", "~> 0.3"

# Caching
gem "redis", "~> 5.0"

# Database & Query
gem "neighbor", "~> 0.4"

# Monitoring & Logging
gem "lograge", "~> 0.14"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors", "~> 3.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

group :development do
  gem "brakeman", "~> 7.1", require: false
  gem "bundler-audit", "~> 0.9", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rubocop", "~> 1.50", require: false
  gem "rubocop-rails", "~> 2.20", require: false
  gem "rubocop-rspec", "~> 3.8", require: false
end

group :development, :test do
  gem "rspec-rails", "~> 6.1"
end

group :test do
  gem "database_cleaner-active_record", "~> 2.1"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 7.0"
end
