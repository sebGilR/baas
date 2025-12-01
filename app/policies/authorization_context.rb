# frozen_string_literal: true

# Context object for Pundit authorization
# Holds additional context beyond just the user (like the current account/tenant)
class AuthorizationContext
  attr_reader :user, :account

  def initialize(user:, account:)
    @user = user
    @account = account
  end

  # Pundit expects the context to respond to certain user methods
  delegate :id, :email, :name, to: :user, allow_nil: true
end
