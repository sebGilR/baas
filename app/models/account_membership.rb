# frozen_string_literal: true

class AccountMembership < ApplicationRecord
  include PublicIdentifiable

  # Associations
  belongs_to :user
  belongs_to :account

  # Validations
  validates :user_id, uniqueness: { scope: :account_id, message: "already a member of this account" }

  # Enums
  enum :role, {
    owner: 0,
    admin: 1,
    editor: 2,
    author: 3,
    viewer: 4
  }, prefix: true

  enum :status, {
    invited: 0,
    active: 1,
    suspended: 2
  }, prefix: true

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
