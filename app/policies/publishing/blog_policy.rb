# frozen_string_literal: true

module Publishing
  class BlogPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present? && belongs_to_account?
    end

    def create?
      user.present? && editor?
    end

    def update?
      user.present? && belongs_to_account? && editor?
    end

    def destroy?
      user.present? && belongs_to_account? && admin?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.where(account: user_account)
      end
    end

    private

    def belongs_to_account?
      record.account_id == user_account&.id
    end
  end
end
