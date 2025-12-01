# frozen_string_literal: true

# Base policy class for all Pundit policies
# Provides common authorization patterns for the application
class ApplicationPolicy
  attr_reader :user, :record, :context

  # @param user [User] The user attempting to perform the action
  # @param record [Object] The record being accessed
  # @param context [AuthorizationContext] Optional context with additional info (account, etc.)
  def initialize(user, record, context = nil)
    @user = user
    @record = record
    @context = context
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
    attr_reader :user, :scope, :context

    def initialize(user, scope, context = nil)
      @user = user
      @scope = scope
      @context = context
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    def user_account
      @user_account ||= context&.account
    end
  end

  private

  def user_account
    @user_account ||= context&.account
  end

  def user_membership
    return nil unless user && user_account

    @user_membership ||= user.account_memberships.find_by(account: user_account)
  end

  def user_role
    user_membership&.role
  end

  def owner?
    user_role == "owner"
  end

  def admin?
    %w[owner admin].include?(user_role)
  end

  def editor?
    %w[owner admin editor].include?(user_role)
  end

  def author?
    %w[owner admin editor author].include?(user_role)
  end

  def viewer?
    user_role.present?
  end
end
