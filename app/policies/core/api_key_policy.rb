# frozen_string_literal: true

module Core
  # Policy for API key management
  # Users can only manage their own API keys within their accounts
  class ApiKeyPolicy < ApplicationPolicy
    def index?
      # Users can list their own API keys
      true
    end

    def show?
      owner?
    end

    def create?
      # Users can create API keys for themselves
      true
    end

    def update?
      # Only the owner can update their API key (e.g., rename)
      owner?
    end

    def destroy?
      # Only the owner can revoke their API key
      owner?
    end

    def revoke?
      owner?
    end

    private

    def owner?
      record.user_id == user.id && record.account_id == user_account&.id
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        # Users can only see their own API keys in the current account
        account = auth_context.is_a?(AuthorizationContext) ? auth_context.account : nil
        user = auth_context.is_a?(AuthorizationContext) ? auth_context.user : auth_context

        if account
          scope.where(user: user, account: account)
        else
          scope.where(user: user)
        end
      end
    end
  end
end
