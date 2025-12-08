# frozen_string_literal: true

# API Key model for machine-to-machine authentication
# Provides an alternative to JWT for scripts, Postman, CI, etc.
# Each key is tied to a user and account for proper multi-tenant scoping
class ApiKey < ApplicationRecord
  include PublicIdentifiable

  # Constants
  KEY_PREFIX_LIVE = "ak_live_"
  KEY_PREFIX_TEST = "ak_test_"
  SECRET_LENGTH = 32

  # Associations
  belongs_to :user
  belongs_to :account

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :prefix, presence: true, uniqueness: true
  validates :secret_digest, presence: true
  validates :scopes, presence: true

  # Enums
  enum :environment, { live: 0, test: 1 }, prefix: true

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :for_environment, ->(env) { where(environment: env) }

  # Class Methods

  # Generates a new API key with a random secret
  # Returns [api_key, raw_secret] - raw_secret is only available at creation time
  def self.generate(user:, account:, name:, scopes: [], environment: :live, expires_at: nil)
    raw_secret = SecureRandom.urlsafe_base64(SECRET_LENGTH)
    prefix = generate_prefix(environment)
    full_token = "#{prefix}.#{raw_secret}"

    api_key = new(
      user: user,
      account: account,
      name: name,
      prefix: prefix,
      secret_digest: digest_secret(raw_secret),
      scopes: scopes,
      environment: environment,
      expires_at: expires_at
    )

    [api_key, full_token]
  end

  def self.generate_prefix(environment)
    base = environment.to_sym == :test ? KEY_PREFIX_TEST : KEY_PREFIX_LIVE
    "#{base}#{SecureRandom.alphanumeric(8)}"
  end

  def self.digest_secret(raw_secret)
    BCrypt::Password.create(raw_secret, cost: 12)
  end

  def self.find_by_prefix(prefix)
    find_by(prefix: prefix)
  end

  # Instance Methods

  def valid_secret?(raw_secret)
    BCrypt::Password.new(secret_digest).is_password?(raw_secret)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
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

  def record_usage!(ip_address: nil)
    update_columns(
      last_used_at: Time.current,
      last_used_ip: ip_address
    )
  end

  # Check if key has a specific scope
  # Supports wildcard patterns like "admin:*"
  def has_scope?(required_scope)
    scopes.any? do |scope|
      scope == required_scope ||
        (scope.end_with?("*") && required_scope.start_with?(scope.chomp("*")))
    end
  end

  # Check if key has all required scopes
  def has_scopes?(required_scopes)
    Array(required_scopes).all? { |scope| has_scope?(scope) }
  end

  # Human-readable description of key status
  def status
    return :revoked if revoked?
    return :expired if expired?

    :active
  end

  # Masked version of the prefix for display
  def masked_prefix
    "#{prefix[0..11]}****"
  end
end
