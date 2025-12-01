# frozen_string_literal: true

module Publishing
  class PostPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present? && belongs_to_account?
    end

    def create?
      user.present? && author?
    end

    def update?
      user.present? && belongs_to_account? && can_edit?
    end

    def destroy?
      user.present? && belongs_to_account? && can_delete?
    end

    def publish?
      user.present? && belongs_to_account? && editor?
    end

    def unpublish?
      user.present? && belongs_to_account? && editor?
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

    def can_edit?
      # Authors can edit their own posts, editors+ can edit any post
      return true if editor?

      author? && record.author_id == user.id
    end

    def can_delete?
      # Only editors+ can delete posts, or authors can delete their own drafts
      return true if editor?

      author? && record.author_id == user.id && record.status_draft?
    end
  end
end
