# 🚀 **baas — Initial Setup & Installation Guide**

Complete guide to bootstrap the Rails 8 API backend with all required dependencies, configurations, and databases.

---

## ✅ **Prerequisites Checklist**

Before proceeding, verify you have all required tools installed:

```bash
# Check Ruby version (requires 3.3+)
ruby -v

# Check Rails version (requires 8.0+)
rails -v

# Check PostgreSQL version (requires 16+)
psql --version

# Check Redis
redis-cli --version

# Check Node.js (optional, for JavaScript tools)
node -v
```

### **macOS Installation (if needed)**

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ruby 3.3.0 (using rbenv)
brew install rbenv ruby-build
rbenv install 3.3.0
rbenv global 3.3.0
rbenv rehash

# Install Rails 8
gem install rails -v '~> 8.0'

# Install PostgreSQL 16
brew install postgresql@16
brew services start postgresql@16

# Install Redis
brew install redis
brew services start redis
```

---

## 🏗️ **Step 1: Initialize Rails 8 API Project**

### **Create the Rails app with API-only setup**

```bash
cd ~/workspace

# Create Rails 8 API-only app with PostgreSQL
rails new baas \
  --api \
  --database=postgresql \
  --skip-bundle \
  --skip-javascript \
  --skip-action-mailbox \
  --skip-action-storage \
  --skip-active-job

cd baas
```

### **Expected structure:**

```
baas/
├── app/
├── config/
├── db/
├── lib/
├── spec/
├── Gemfile
├── config.ru
├── Rakefile
└── ...
```

---

## 📦 **Step 2: Update & Configure Gemfile**

Replace your `Gemfile` with the production-ready configuration:

```ruby
# See https://guides.rubyonrails.org/gemfile.html

source "https://rubygems.org"

ruby "~> 3.3.0"

# Rails & Core
gem "rails", "~> 8.0.0"
gem "puma", "~> 6.0"
gem "pg", "~> 1.5"

# API & Serialization
gem "jsonapi-serializer", "~> 2.2"
gem "pundit", "~> 2.3"

# Multi-Tenancy
gem "acts-as-tenant", "~> 0.5.1"

# Authentication & Authorization
gem "jwt", "~> 2.7"
gem "bcrypt", "~> 3.1"

# Background Jobs (undecided - adding popular option)
gem "solid_queue", "~> 0.3"

# Caching
gem "redis", "~> 5.0"

# Database & Query
gem "pgvector", "~> 0.3"

# Monitoring & Logging
gem "lograge", "~> 0.14"

# Development & Testing
group :development do
  gem "debug", ">= 1.0.0", platforms: %i[ mri mingw x64_mingw ]
  gem "rubocop", "~> 1.50", require: false
  gem "rubocop-rails", "~> 2.20", require: false
  gem "rubocop-rspec", "~> 2.20", require: false
  gem "brakeman", "~> 6.0", require: false
  gem "bundler-audit", "~> 0.9", require: false
end

group :test do
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 5.3"
  gem "database_cleaner-active_record", "~> 2.1"
end

group :development, :test do
  gem "rspec-rails", "~> 6.1"
end
```

---

## 🔧 **Step 3: Install Gems & Configure Database**

```bash
# Install all gems
bundle install

# Create database
rails db:create

# Enable pgvector extension
rails db:execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
rails db:execute 'CREATE EXTENSION IF NOT EXISTS "pgvector"'
```

---

## 🗄️ **Step 4: Database Configuration**

### **Update `config/database.yml`:**

Ensure PostgreSQL connection is configured (usually auto-generated):

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: baas_development

test:
  <<: *default
  database: baas_test

production:
  <<: *default
  database: baas_production
  url: <%= ENV.fetch("DATABASE_URL") %>
```

---

## 🔐 **Step 5: Environment Configuration**

### **Create `config/.env.local` (add to `.gitignore`)**

```bash
# Authentication
JWT_SECRET_KEY=your-super-secret-key-change-in-production
JWT_ACCESS_TOKEN_EXPIRY=900
JWT_REFRESH_TOKEN_EXPIRY=2592000

# Redis
REDIS_URL=redis://localhost:6379/0

# Database
DATABASE_URL=postgresql://localhost/baas_development

# Rails
RAILS_ENV=development
RACK_ENV=development
```

### **Update `.gitignore`:**

```bash
# Add after existing entries
.env.local
.env.*.local
```

---

## ⚙️ **Step 6: Configure Rails for API**

### **Update `config/application.rb`:**

```ruby
require_relative "boot"

require "rails/all"

# Only require the railties we need for API mode
Bundler.require(*Rails.groups)

module Baas
  class Application < Rails::Application
    config.load_defaults 8.0

    # API-only configuration
    config.api_only = true
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # JSON response formatting
    config.to_prepare do
      config.action_controller.default_protect_from_forgery = false
    end

    # Lograge for structured logging
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
  end
end
```

### **Create `config/initializers/cors.rb`:**

```ruby
# Configure CORS for frontend access (adjust for production)
Rails.application.config.middleware.insert_before 0, "Rack::Cors" do
  allow do
    origins "localhost:3000", "localhost:3001", "127.0.0.1:3000"
    resource "*", headers: :any, methods: [:get, :post, :put, :patch, :delete]
  end
end
```

Add `rack-cors` to `Gemfile`:
```ruby
gem "rack-cors", "~> 2.0"
```

---

## 🧪 **Step 7: Configure RSpec Testing**

### **Generate RSpec configuration:**

```bash
bundle exec rails generate rspec:install
```

### **Update `spec/spec_helper.rb`:**

```ruby
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
```

### **Update `spec/rails_helper.rb`:**

```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'database_cleaner/active_record'
require 'shoulda/matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

---

## 📐 **Step 8: Create Module Structure**

Create the directory structure for namespaced modules:

```bash
# Create model directories for each bounded context
mkdir -p app/models/core
mkdir -p app/models/publishing
mkdir -p app/models/ai_assistant
mkdir -p app/models/analytics

# Create service directories
mkdir -p app/services/core/authentication
mkdir -p app/services/core/accounts
mkdir -p app/services/publishing/posts
mkdir -p app/services/publishing/drafts
mkdir -p app/services/ai_assistant/content
mkdir -p app/services/ai_assistant/embeddings
mkdir -p app/services/analytics

# Create policy directories
mkdir -p app/policies/core
mkdir -p app/policies/publishing
mkdir -p app/policies/ai_assistant
mkdir -p app/policies/analytics

# Create serializer directories
mkdir -p app/serializers/api/v1

# Create job directories
mkdir -p app/jobs/core
mkdir -p app/jobs/publishing
mkdir -p app/jobs/ai_assistant
mkdir -p app/jobs/analytics
```

### **Configure routes in `config/routes.rb`:**

```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/login', to: 'authentication#login'
      post 'auth/register', to: 'authentication#register'
      post 'auth/refresh', to: 'authentication#refresh'
      post 'auth/logout', to: 'authentication#logout'
      
      # Resource routes will be defined here
      resources :accounts, only: [:index, :show, :create, :update]
      resources :users, only: [:index, :show, :update]
      resources :blogs
      resources :posts
      resources :drafts
    end
  end
end
```

---

## 🛣️ **Step 9: Create Application Scaffolding**

### **Create ApplicationController:**

```bash
touch app/controllers/application_controller.rb
```

### **Create base service class:**

```bash
mkdir -p app/services
touch app/services/application_service.rb
```

### **Create API v1 base controller:**

```bash
mkdir -p app/controllers/api/v1
touch app/controllers/api/v1/application_controller.rb
```

---

## 🔍 **Step 10: Code Quality Setup**

### **Generate RuboCop configuration:**

```bash
bundle exec rubocop --init --no-index > .rubocop.yml
```

### **Update `.rubocop.yml`:**

```yaml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.4
  Exclude:
    - 'bin/**/*'
    - 'db/**/*'
    - 'vendor/**/*'
    - 'tmp/**/*'
    - 'node_modules/**/*'

Layout/LineLength:
  Max: 100

Style/Documentation:
  Enabled: false

Style/StringLiterals:
  EnforcedStyle: double_quotes

Style/StringLiteralsInInterpolation:
  EnforcedStyle: double_quotes

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'
```

### **Run security checks:**

```bash
# Check for vulnerabilities
bundle audit

# Run static security analysis
bundle exec brakeman -q
```

---

## ✨ **Step 11: Verify Setup**

```bash
# Run tests to verify everything works
bundle exec rspec

# Check for linting issues
bundle exec rubocop --fix

# Run security checks
bundle audit
bundle exec brakeman
```

---

## 🚀 **Step 12: Start Development Server**

```bash
# Start the Rails server
rails s -p 3000

# In another terminal, optionally start Solid Queue worker (when background jobs are configured)
# bundle exec rake solid_queue:start
```

Expected output:
```
=> Rails 8.0.0 application starting in development 🎉
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.x.x (ruby 3.3.0-p0-x86_64-darwin23)
* Min threads: 5, max threads: 5
* Environment: development
* PID: 12345
* Listening on http://127.0.0.1:3000
Use Ctrl-C to stop
```

---

## 📝 **Next Steps After Setup**

1. **Create Core Engine Models** → User, Account, AccountMembership, RefreshToken
2. **Implement Authentication** → JWT tokens, login/register endpoints
3. **Set up Multi-Tenancy** → Tenant context middleware, account scoping
4. **Generate Documentation** → OpenAPI/Swagger configuration
5. **Create Core Models** → User, Account, AccountMembership, RefreshToken
6. **Create Publishing Models** → Blog, Post, Draft models

---

## 🆘 **Troubleshooting**

### **PostgreSQL Connection Failed**

```bash
# Restart PostgreSQL
brew services restart postgresql@16

# Reset database
rails db:drop db:create
```

### **Redis Connection Failed**

```bash
# Restart Redis
brew services restart redis

# Verify Redis is running
redis-cli ping
# Should return: PONG
```

### **Bundle Install Issues**

```bash
# Clear Bundler cache
bundle cache --no-prune

# Reinstall
bundle install --local
```

### **RSpec Not Finding Tests**

```bash
# Ensure spec directory exists
mkdir -p spec

# Regenerate RSpec
bundle exec rails generate rspec:install
```

---

## 📚 **Documentation References**

- [Rails 8 API Guides](https://guides.rubyonrails.org/api_app.html)
- [JWT Authentication](https://jwt.io/)
- [acts-as-tenant Documentation](https://github.com/ErwinM/acts-as-tenant)
- [Pundit Authorization](https://github.com/varvet/pundit)
- [JSONAPI Serializer](https://github.com/jsonapi-serializer/jsonapi-serializer)

---

## ✅ **Setup Complete Checklist**

- [ ] Ruby 3.3+ installed
- [ ] PostgreSQL 14+ running
- [ ] Redis running
- [ ] Rails 8 app created
- [ ] Gems installed
- [ ] Database created with extensions
- [ ] Environment variables configured
- [ ] RSpec installed and configured
- [ ] RuboCop configured
- [ ] Module directories created
- [ ] Routes configured
- [ ] Development server starts successfully
- [ ] Tests pass

**You're ready to start building! 🚀**
