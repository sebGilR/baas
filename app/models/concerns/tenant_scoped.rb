# frozen_string_literal: true

# Concern for models that are scoped to a tenant (account)
# This provides common tenant-related functionality
module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant :account
    belongs_to :account

    validates :account, presence: true

    scope :for_account, ->(account) { where(account: account) }
  end

  class_methods do
    # Find a record by public_id ensuring tenant scoping
    def find_by_public_id_for_account(public_id, account)
      where(account: account).find_by(public_id: public_id)
    end

    def find_by_public_id_for_account!(public_id, account)
      where(account: account).find_by!(public_id: public_id)
    end
  end
end
