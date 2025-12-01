# frozen_string_literal: true

module Publishing
  class DraftPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present? && belongs_to_account? && can_view?
    end

    def create?
      user.present? && author?
    end

    def update?
      user.present? && belongs_to_account? && can_edit?
    end

    def destroy?
      user.present? && belongs_to_account? && can_edit?
    end

    def autosave?
      update?
    end

    def convert_to_post?
      user.present? && belongs_to_account? && can_edit?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if editor?
          # Editors can see all drafts in the account
          scope.where(account: user_account)
        else
          # Authors can only see their own drafts
          scope.where(account: user_account, author_id: user.id)
        end
      end

      private

      def editor?
        return false unless user && user_account

        membership = user.account_memberships.find_by(account: user_account)
        %w[owner admin editor].include?(membership&.role)
      end
    end

    private

    def belongs_to_account?
      record.account_id == user_account&.id
    end

    def can_view?
      # Editors can view all drafts, authors can only view their own
      return true if editor?

      record.author_id == user.id
    end

    def can_edit?
      # Authors can only edit their own drafts, editors+ can edit any
      return true if editor?

      record.author_id == user.id
    end
  end
end
