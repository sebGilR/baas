# frozen_string_literal: true

# Base policy class for all Pundit policies
# Provides common authorization patterns for the application
class ApplicationPolicy
  attr_reader :auth_context, :record

  # @param auth_context [AuthorizationContext] The authorization context (user + account)
  # @param record [Object] The record being accessed
  def initialize(auth_context, record)
    @auth_context = auth_context
    @record = record
  end

  # Access the user from the authorization context
  def user
    auth_context.is_a?(AuthorizationContext) ? auth_context.user : auth_context
  end

  # Access the account from the authorization context
  def user_account
    auth_context.is_a?(AuthorizationContext) ? auth_context.account : nil
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :auth_context, :scope

    def initialize(auth_context, scope)
      @auth_context = auth_context
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    # Access the user from the authorization context
    def user
      auth_context.is_a?(AuthorizationContext) ? auth_context.user : auth_context
    end

    # Access the account from the authorization context
    def user_account
      auth_context.is_a?(AuthorizationContext) ? auth_context.account : nil
    end
  end

  private

  def user_membership
    return unless user && user_account

    if defined?(@user_membership)
      @user_membership
    else
      @user_membership = user.account_memberships.find_by(account: user_account)
    end
  end

  def user_role
    user_membership&.role
  end

  def owner?
    user_role == "owner"
  end

  def admin?
    ["owner", "admin"].include?(user_role)
  end

  def editor?
    ["owner", "admin", "editor"].include?(user_role)
  end

  def author?
    ["owner", "admin", "editor", "author"].include?(user_role)
  end

  def viewer?
    user_role.present?
  end
end
