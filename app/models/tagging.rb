# frozen_string_literal: true

class Tagging < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  # Validations
  validates :tag_id, uniqueness: {
    scope: [:account_id, :taggable_type, :taggable_id],
    message: "has already been applied to this item"
  }

  # Scopes
  scope :for_posts, -> { where(taggable_type: "Post") }
  scope :for_drafts, -> { where(taggable_type: "Draft") }
  scope :ordered, -> { order(created_at: :desc) }
end
