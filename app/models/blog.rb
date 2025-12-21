# frozen_string_literal: true

class Blog < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  has_many :posts, dependent: :destroy
  has_many :drafts, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { scope: :account_id, message: "has already been taken for this account" },
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }

  # Enums
  enum :status, { active: 0, archived: 1, deleted: 2 }, prefix: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :ordered, -> { order(created_at: :desc, id: :desc) }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Instance Methods
  def published_posts
    posts.published
  end

  def post_count
    posts.count
  end

  private

  def generate_slug
    return if slug.present? || name.blank?

    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1

    while Blog.exists?(slug: candidate_slug, account_id: account_id)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
