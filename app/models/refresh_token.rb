# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  include PublicIdentifiable

  # Associations
  belongs_to :user

  # Validations
  validates :jti, presence: true, uniqueness: true
  validates :token_digest, presence: true
  validates :expires_at, presence: true

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(expires_at: ..Time.current) }
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
