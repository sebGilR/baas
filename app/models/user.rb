# frozen_string_literal: true

class User < ApplicationRecord
  include PublicIdentifiable

  has_secure_password

  # Associations
  has_many :account_memberships, dependent: :destroy
  has_many :accounts, through: :account_memberships
  has_many :refresh_tokens, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2 }

  # Callbacks
  before_validation :normalize_email, on: :create

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
