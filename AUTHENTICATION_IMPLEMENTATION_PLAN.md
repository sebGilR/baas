


# 🎯 **End-to-End Authentication Implementation Plan**

**Goal:** Working registration, login, refresh, and logout endpoints with full test coverage

**Status:** Ready to implement  
**Created:** November 23, 2025

---

## 📋 **Implementation Plan: Authentication Feature (Complete Vertical Slice)**

### **Phase 1: Database Foundation** ⏱️ ~1 hour

#### **1.1 Enable UUID Extension + UUIDv7 Function**
```sql
-- db/migrate/[timestamp]_enable_pgcrypto_and_uuid_functions.rb
- Enable pgcrypto extension
- Create gen_uuidv7() function for sequential UUIDs
```

#### **1.2 Create Users Table**
```ruby
# db/migrate/[timestamp]_create_users.rb
- id (bigint PK)
- public_id (uuid, default: gen_uuidv7())
- email (string, unique, not null)
- password_digest (string, not null)
- name (string, not null)
- timestamps
- Indexes: public_id (unique), email (unique)
```

#### **1.3 Create Accounts Table**
```ruby
# db/migrate/[timestamp]_create_accounts.rb
- id (bigint PK)
- public_id (uuid, default: gen_uuidv7())
- name (string, not null)
- slug (string, unique, not null)
- status (integer, default: 0) # enum: active, suspended, deleted
- plan (integer, default: 0) # enum: free, pro, team
- timestamps
- Indexes: public_id (unique), slug (unique)
```

#### **1.4 Create AccountMemberships Table**
```ruby
# db/migrate/[timestamp]_create_account_memberships.rb
- id (bigint PK)
- public_id (uuid, default: gen_uuidv7())
- user_id (bigint FK, not null)
- account_id (bigint FK, not null)
- role (integer, default: 0) # enum: owner, admin, editor, author, viewer
- status (integer, default: 0) # enum: invited, active, suspended
- timestamps
- Indexes: 
  - [user_id, account_id] (unique)
  - user_id
  - account_id
  - public_id (unique)
```

#### **1.5 Create RefreshTokens Table**
```ruby
# db/migrate/[timestamp]_create_refresh_tokens.rb
- id (bigint PK)
- public_id (uuid, default: gen_uuidv7())
- user_id (bigint FK, not null)
- jti (string, unique, not null) # JWT ID for revocation
- token_digest (string, not null) # Hashed token for security
- expires_at (datetime, not null)
- revoked_at (datetime, nullable)
- device_info (jsonb, default: {})
- last_used_at (datetime)
- timestamps
- Indexes:
  - jti (unique)
  - user_id
  - [user_id, revoked_at]
  - public_id (unique)
```

---

### **Phase 2: Models with Validations** ⏱️ ~1.5 hours

#### **2.1 User Model**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  # Associations
  has_many :account_memberships, dependent: :destroy
  has_many :accounts, through: :account_memberships
  has_many :refresh_tokens, dependent: :destroy
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2 }
  validates :public_id, presence: true, uniqueness: true
  
  # Callbacks
  before_validation :normalize_email
  
  # Instance Methods
  def primary_account
    accounts.first # Later: add logic for default_account_id
  end
  
  def role_for_account(account)
    account_memberships.find_by(account: account)&.role
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end

# spec/models/user_spec.rb - Full test coverage
```

#### **2.2 Account Model**
```ruby
# app/models/account.rb
class Account < ApplicationRecord
  # Associations
  has_many :account_memberships, dependent: :destroy
  has_many :users, through: :account_memberships
  
  # Validations
  validates :name, presence: true, length: { minimum: 2 }
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :public_id, presence: true, uniqueness: true
  
  # Enums
  enum status: { active: 0, suspended: 1, deleted: 2 }, _prefix: true
  enum plan: { free: 0, pro: 1, team: 2 }, _prefix: true
  
  # Callbacks
  before_validation :generate_slug, on: :create
  
  # Scopes
  scope :active, -> { where(status: :active) }
  
  private
  
  def generate_slug
    return if slug.present?
    
    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1
    
    while Account.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = candidate_slug
  end
end

# spec/models/account_spec.rb - Full test coverage
```

#### **2.3 AccountMembership Model**
```ruby
# app/models/account_membership.rb
class AccountMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :account
  
  # Validations
  validates :user_id, uniqueness: { scope: :account_id, message: "already a member of this account" }
  validates :public_id, presence: true, uniqueness: true
  
  # Enums
  enum role: { 
    owner: 0, 
    admin: 1, 
    editor: 2, 
    author: 3, 
    viewer: 4 
  }, _prefix: true
  
  enum status: { 
    invited: 0, 
    active: 1, 
    suspended: 2 
  }, _prefix: true
  
  # Scopes
  scope :active, -> { where(status: :active) }
  scope :for_account, ->(account) { where(account: account) }
  
  # Instance Methods
  def can_manage_users?
    role_owner? || role_admin?
  end
  
  def can_publish?
    role_owner? || role_admin? || role_editor?
  end
end

# spec/models/account_membership_spec.rb - Full test coverage
```

#### **2.4 RefreshToken Model**
```ruby
# app/models/refresh_token.rb
class RefreshToken < ApplicationRecord
  # Associations
  belongs_to :user
  
  # Validations
  validates :jti, presence: true, uniqueness: true
  validates :token_digest, presence: true
  validates :expires_at, presence: true
  validates :public_id, presence: true, uniqueness: true
  
  # Scopes
  scope :active, -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  
  # Instance Methods
  def expired?
    expires_at <= Time.current
  end
  
  def revoked?
    revoked_at.present?
  end
  
  def active?
    !expired? && !revoked?
  end
  
  def revoke!
    update!(revoked_at: Time.current)
  end
  
  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end

# spec/models/refresh_token_spec.rb - Full test coverage
```

---

### **Phase 3: Model Concerns** ⏱️ ~30 min

#### **3.1 PublicIdentifiable Concern**
```ruby
# app/models/concerns/public_identifiable.rb
module PublicIdentifiable
  extend ActiveSupport::Concern
  
  included do
    # Public ID is set by database default gen_uuidv7()
    # No need to set in Rails, but we validate presence
    validates :public_id, presence: true, uniqueness: true
  end
  
  class_methods do
    def find_by_public_id(public_id)
      find_by(public_id: public_id)
    end
    
    def find_by_public_id!(public_id)
      find_by!(public_id: public_id)
    end
  end
  
  def to_param
    public_id
  end
end

# Include in models:
# include PublicIdentifiable
```

---

### **Phase 4: Service Objects** ⏱️ ~3 hours

#### **4.1 Base Service Pattern**
```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs).call(&block)
  end
  
  def call
    raise NotImplementedError
  end
  
  private
  
  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end
  
  def failure(errors:, data: {})
    ServiceResult.new(success: false, errors: errors, data: data)
  end
end

# app/services/service_result.rb
class ServiceResult
  attr_reader :data, :errors
  
  def initialize(success:, data: {}, errors: nil)
    @success = success
    @data = OpenStruct.new(data)
    @errors = errors
  end
  
  def success?
    @success
  end
  
  def failure?
    !@success
  end
end
```

#### **4.2 JWT Services**
```ruby
# app/services/core/authentication/generate_jwt_service.rb
module Core
  module Authentication
    class GenerateJwtService < ApplicationService
      def initialize(user:, account:)
        @user = user
        @account = account
      end
      
      def call
        access_token = generate_access_token
        success(access_token: access_token)
      end
      
      private
      
      attr_reader :user, :account
      
      def generate_access_token
        payload = {
          sub: user.public_id,
          account_id: account.public_id,
          email: user.email,
          role: user.role_for_account(account),
          exp: 30.minutes.from_now.to_i,
          iat: Time.current.to_i
        }
        
        JWT.encode(payload, jwt_secret, 'HS256')
      end
      
      def jwt_secret
        Rails.application.credentials.secret_key_base
      end
    end
  end
end

# app/services/core/authentication/decode_jwt_service.rb
module Core
  module Authentication
    class DecodeJwtService < ApplicationService
      def initialize(token:)
        @token = token
      end
      
      def call
        payload = decode_token
        return failure(errors: 'Invalid token') unless payload
        
        success(payload: payload)
      rescue JWT::ExpiredSignature
        failure(errors: 'Token has expired')
      rescue JWT::DecodeError
        failure(errors: 'Invalid token')
      end
      
      private
      
      attr_reader :token
      
      def decode_token
        JWT.decode(token, jwt_secret, true, algorithm: 'HS256').first
      end
      
      def jwt_secret
        Rails.application.credentials.secret_key_base
      end
    end
  end
end

# spec/services/core/authentication/*_spec.rb - Full test coverage
```

#### **4.3 Registration Service**
```ruby
# app/services/core/authentication/register_service.rb
module Core
  module Authentication
    class RegisterService < ApplicationService
      def initialize(email:, password:, name:, account_name: nil)
        @email = email
        @password = password
        @name = name
        @account_name = account_name || "#{name}'s Account"
      end
      
      def call
        ActiveRecord::Base.transaction do
          user = create_user
          return failure(errors: user.errors.full_messages) unless user.persisted?
          
          account = create_account_for_user(user)
          return failure(errors: account.errors.full_messages) unless account.persisted?
          
          membership = create_membership(user, account)
          return failure(errors: membership.errors.full_messages) unless membership.persisted?
          
          tokens = generate_tokens(user, account)
          
          success(
            user: user,
            account: account,
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token],
            expires_in: 1800
          )
        end
      rescue => e
        failure(errors: e.message)
      end
      
      private
      
      attr_reader :email, :password, :name, :account_name
      
      def create_user
        User.create(
          email: email,
          password: password,
          name: name
        )
      end
      
      def create_account_for_user(user)
        Account.create(
          name: account_name,
          status: :active,
          plan: :free
        )
      end
      
      def create_membership(user, account)
        AccountMembership.create(
          user: user,
          account: account,
          role: :owner,
          status: :active
        )
      end
      
      def generate_tokens(user, account)
        # Access token
        access_result = GenerateJwtService.call(user: user, account: account)
        
        # Refresh token
        refresh_token = SecureRandom.urlsafe_base64(32)
        jti = SecureRandom.uuid
        
        RefreshToken.create!(
          user: user,
          jti: jti,
          token_digest: Digest::SHA256.hexdigest(refresh_token),
          expires_at: 30.days.from_now,
          device_info: {} # Will add from request later
        )
        
        {
          access_token: access_result.data.access_token,
          refresh_token: refresh_token
        }
      end
    end
  end
end

# spec/services/core/authentication/register_service_spec.rb - Full test coverage
```

#### **4.4 Login Service**
```ruby
# app/services/core/authentication/login_service.rb
module Core
  module Authentication
    class LoginService < ApplicationService
      def initialize(email:, password:, device_info: {})
        @email = email
        @password = password
        @device_info = device_info
      end
      
      def call
        user = find_user
        return failure(errors: 'Invalid email or password') unless user
        return failure(errors: 'Invalid email or password') unless user.authenticate(password)
        
        account = user.primary_account
        return failure(errors: 'No account found') unless account
        
        tokens = generate_tokens(user, account)
        
        success(
          user: user,
          account: account,
          access_token: tokens[:access_token],
          refresh_token: tokens[:refresh_token],
          expires_in: 1800
        )
      end
      
      private
      
      attr_reader :email, :password, :device_info
      
      def find_user
        User.find_by(email: email.downcase.strip)
      end
      
      def generate_tokens(user, account)
        # Access token
        access_result = GenerateJwtService.call(user: user, account: account)
        
        # Refresh token
        refresh_token = SecureRandom.urlsafe_base64(32)
        jti = SecureRandom.uuid
        
        RefreshToken.create!(
          user: user,
          jti: jti,
          token_digest: Digest::SHA256.hexdigest(refresh_token),
          expires_at: 30.days.from_now,
          device_info: device_info
        )
        
        {
          access_token: access_result.data.access_token,
          refresh_token: refresh_token
        }
      end
    end
  end
end

# spec/services/core/authentication/login_service_spec.rb
```

#### **4.5 Refresh Token Service**
```ruby
# app/services/core/authentication/refresh_token_service.rb
module Core
  module Authentication
    class RefreshTokenService < ApplicationService
      def initialize(refresh_token:)
        @refresh_token = refresh_token
      end
      
      def call
        token_record = find_token_record
        return failure(errors: 'Invalid refresh token') unless token_record
        return failure(errors: 'Token expired') if token_record.expired?
        return failure(errors: 'Token revoked') if token_record.revoked?
        
        user = token_record.user
        account = user.primary_account
        
        # Generate new tokens
        new_tokens = rotate_tokens(token_record, user, account)
        
        success(
          user: user,
          account: account,
          access_token: new_tokens[:access_token],
          refresh_token: new_tokens[:refresh_token],
          expires_in: 1800
        )
      end
      
      private
      
      attr_reader :refresh_token
      
      def find_token_record
        token_digest = Digest::SHA256.hexdigest(refresh_token)
        RefreshToken.find_by(token_digest: token_digest)
      end
      
      def rotate_tokens(old_token, user, account)
        ActiveRecord::Base.transaction do
          # Revoke old token
          old_token.revoke!
          
          # Generate new access token
          access_result = GenerateJwtService.call(user: user, account: account)
          
          # Generate new refresh token
          new_refresh_token = SecureRandom.urlsafe_base64(32)
          jti = SecureRandom.uuid
          
          RefreshToken.create!(
            user: user,
            jti: jti,
            token_digest: Digest::SHA256.hexdigest(new_refresh_token),
            expires_at: 30.days.from_now,
            device_info: old_token.device_info
          )
          
          {
            access_token: access_result.data.access_token,
            refresh_token: new_refresh_token
          }
        end
      end
    end
  end
end

# spec/services/core/authentication/refresh_token_service_spec.rb
```

#### **4.6 Logout Service**
```ruby
# app/services/core/authentication/logout_service.rb
module Core
  module Authentication
    class LogoutService < ApplicationService
      def initialize(refresh_token:)
        @refresh_token = refresh_token
      end
      
      def call
        token_record = find_token_record
        return failure(errors: 'Invalid refresh token') unless token_record
        
        token_record.revoke!
        
        success(message: 'Logged out successfully')
      end
      
      private
      
      attr_reader :refresh_token
      
      def find_token_record
        token_digest = Digest::SHA256.hexdigest(refresh_token)
        RefreshToken.find_by(token_digest: token_digest)
      end
    end
  end
end

# spec/services/core/authentication/logout_service_spec.rb
```

---

### **Phase 5: Controllers & Routing** ⏱️ ~2 hours

#### **5.1 Base API Controller**
```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      
      private
      
      def not_found(exception)
        render json: {
          errors: [{
            status: '404',
            title: 'Not Found',
            detail: exception.message
          }]
        }, status: :not_found
      end
      
      def unprocessable_entity(exception)
        render json: {
          errors: [{
            status: '422',
            title: 'Unprocessable Entity',
            detail: exception.message
          }]
        }, status: :unprocessable_entity
      end
    end
  end
end
```

#### **5.2 Registrations Controller**
```ruby
# app/controllers/api/v1/auth/registrations_controller.rb
module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        def create
          result = Core::Authentication::RegisterService.call(
            email: registration_params[:email],
            password: registration_params[:password],
            name: registration_params[:name],
            account_name: registration_params[:account_name]
          )
          
          if result.success?
            render json: {
              data: {
                type: 'authentication',
                attributes: {
                  user: UserSerializer.new(result.data.user).serializable_hash[:data][:attributes],
                  account: AccountSerializer.new(result.data.account).serializable_hash[:data][:attributes],
                  access_token: result.data.access_token,
                  refresh_token: result.data.refresh_token,
                  token_type: 'Bearer',
                  expires_in: result.data.expires_in
                }
              }
            }, status: :created
          else
            render json: {
              errors: [{
                status: '422',
                title: 'Registration Failed',
                detail: result.errors
              }]
            }, status: :unprocessable_entity
          end
        end
        
        private
        
        def registration_params
          params.require(:data).require(:attributes).permit(:email, :password, :name, :account_name)
        end
      end
    end
  end
end

# spec/requests/api/v1/auth/registrations_spec.rb
```

#### **5.3 Sessions Controller**
```ruby
# app/controllers/api/v1/auth/sessions_controller.rb
module Api
  module V1
    module Auth
      class SessionsController < BaseController
        def create
          result = Core::Authentication::LoginService.call(
            email: login_params[:email],
            password: login_params[:password],
            device_info: extract_device_info
          )
          
          if result.success?
            render json: authentication_response(result), status: :ok
          else
            render json: {
              errors: [{
                status: '401',
                title: 'Authentication Failed',
                detail: result.errors
              }]
            }, status: :unauthorized
          end
        end
        
        private
        
        def login_params
          params.require(:data).require(:attributes).permit(:email, :password)
        end
        
        def extract_device_info
          {
            user_agent: request.user_agent,
            ip_address: request.remote_ip
          }
        end
        
        def authentication_response(result)
          {
            data: {
              type: 'authentication',
              attributes: {
                user: UserSerializer.new(result.data.user).serializable_hash[:data][:attributes],
                account: AccountSerializer.new(result.data.account).serializable_hash[:data][:attributes],
                access_token: result.data.access_token,
                refresh_token: result.data.refresh_token,
                token_type: 'Bearer',
                expires_in: result.data.expires_in
              }
            }
          }
        end
      end
    end
  end
end

# spec/requests/api/v1/auth/sessions_spec.rb
```

#### **5.4 Refresh Tokens Controller**
```ruby
# app/controllers/api/v1/auth/refresh_tokens_controller.rb
module Api
  module V1
    module Auth
      class RefreshTokensController < BaseController
        def create
          result = Core::Authentication::RefreshTokenService.call(
            refresh_token: refresh_params[:refresh_token]
          )
          
          if result.success?
            render json: {
              data: {
                type: 'authentication',
                attributes: {
                  access_token: result.data.access_token,
                  refresh_token: result.data.refresh_token,
                  token_type: 'Bearer',
                  expires_in: result.data.expires_in
                }
              }
            }, status: :ok
          else
            render json: {
              errors: [{
                status: '401',
                title: 'Token Refresh Failed',
                detail: result.errors
              }]
            }, status: :unauthorized
          end
        end
        
        def destroy
          result = Core::Authentication::LogoutService.call(
            refresh_token: refresh_params[:refresh_token]
          )
          
          if result.success?
            head :no_content
          else
            render json: {
              errors: [{
                status: '400',
                title: 'Logout Failed',
                detail: result.errors
              }]
            }, status: :bad_request
          end
        end
        
        private
        
        def refresh_params
          params.require(:data).require(:attributes).permit(:refresh_token)
        end
      end
    end
  end
end

# spec/requests/api/v1/auth/refresh_tokens_spec.rb
```

#### **5.5 Routes**
```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post 'register', to: 'registrations#create'
        post 'login', to: 'sessions#create'
        post 'refresh', to: 'refresh_tokens#create'
        delete 'logout', to: 'refresh_tokens#destroy'
      end
    end
  end
end
```

---

### **Phase 6: Serializers** ⏱️ ~1 hour

```ruby
# app/serializers/api/v1/user_serializer.rb
module Api
  module V1
    class UserSerializer
      include JSONAPI::Serializer
      
      set_id :public_id
      attributes :email, :name, :created_at
    end
  end
end

# app/serializers/api/v1/account_serializer.rb
module Api
  module V1
    class AccountSerializer
      include JSONAPI::Serializer
      
      set_id :public_id
      attributes :name, :slug, :plan, :status, :created_at
    end
  end
end
```

---

### **Phase 7: Factories** ⏱️ ~30 min

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'Password123!' }
    name { Faker::Name.name }
  end
end

# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    status { :active }
    plan { :free }
  end
end

# spec/factories/account_memberships.rb
FactoryBot.define do
  factory :account_membership do
    association :user
    association :account
    role { :owner }
    status { :active }
  end
end

# spec/factories/refresh_tokens.rb
FactoryBot.define do
  factory :refresh_token do
    association :user
    jti { SecureRandom.uuid }
    token_digest { Digest::SHA256.hexdigest(SecureRandom.urlsafe_base64(32)) }
    expires_at { 30.days.from_now }
    device_info { {} }
  end
end
```

---

## 📊 **Implementation Summary**

| Phase | Components | Time Estimate |
|-------|------------|---------------|
| 1 | Migrations (4 tables + UUID setup) | 1 hour |
| 2 | Models (4 models + validations) | 1.5 hours |
| 3 | Concerns (PublicIdentifiable) | 30 min |
| 4 | Services (6 services + specs) | 3 hours |
| 5 | Controllers (3 controllers + routes + specs) | 2 hours |
| 6 | Serializers (2 serializers) | 1 hour |
| 7 | Factories (4 factories) | 30 min |
| **Total** | **Full auth system** | **~9.5 hours** |

---

## 🎯 **Bruno Collection Structure**

```
Authentication Collection/
├── 01_Register.bru
├── 02_Login.bru
├── 03_Refresh_Token.bru
└── 04_Logout.bru
```

### **Example Request Format (JSON:API)**

```json
// POST /api/v1/auth/register
{
  "data": {
    "type": "authentication",
    "attributes": {
      "email": "user@example.com",
      "password": "Password123!",
      "name": "John Doe",
      "account_name": "My Blog"
    }
  }
}

// Response
{
  "data": {
    "type": "authentication",
    "attributes": {
      "user": {
        "id": "uuid-here",
        "email": "user@example.com",
        "name": "John Doe"
      },
      "account": {
        "id": "uuid-here",
        "name": "My Blog",
        "slug": "my-blog"
      },
      "access_token": "eyJhbGci...",
      "refresh_token": "abc123...",
      "token_type": "Bearer",
      "expires_in": 1800
    }
  }
}
```

---

## ✅ **Acceptance Criteria**

- [ ] User can register with email/password
- [ ] Registration auto-creates account with owner role
- [ ] User can login and receive access + refresh tokens
- [ ] Access token contains user_id, account_id, role
- [ ] User can refresh access token with refresh token
- [ ] Refresh token rotation works (old token revoked)
- [ ] User can logout (revokes refresh token)
- [ ] All endpoints return JSON:API format
- [ ] All services have >80% test coverage
- [ ] All request specs pass
- [ ] All model specs pass
- [ ] Bruno collection can test all endpoints

---

## 🔄 **Testing Strategy**

### **Unit Tests (Models)**
- User validations, password encryption
- Account slug generation
- AccountMembership role queries
- RefreshToken expiration/revocation logic

### **Unit Tests (Services)**
- JWT generation/decoding
- Registration flow
- Login flow
- Token refresh rotation
- Logout revocation

### **Integration Tests (Request Specs)**
- Full registration flow
- Full login flow
- Token refresh flow
- Logout flow
- Error handling (invalid credentials, expired tokens, etc.)

---

## 🚀 **Ready to Start!**

Once implementation is complete:
1. ✅ All migrations run successfully
2. ✅ All models tested
3. ✅ All services tested
4. ✅ All controllers tested
5. ✅ Bruno collection created
6. ✅ Manual API testing passes
7. ✅ Ready for multi-tenancy middleware (Phase 1C)

---

**Next Steps:** Start with Phase 1 (Migrations) and work through each phase sequentially.
