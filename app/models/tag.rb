# frozen_string_literal: true

class Tag < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  has_many :taggings, dependent: :destroy
  has_many :posts, through: :taggings, source: :taggable, source_type: "Post"
  has_many :drafts, through: :taggings, source: :taggable, source_type: "Draft"

  # Validations
  validates :name, presence: true,
                   length: { minimum: 1, maximum: 50 },
                   uniqueness: { scope: :account_id, case_sensitive: false }
  validates :slug, presence: true,
                   uniqueness: { scope: :account_id },
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" },
                    allow_blank: true

  # Scopes
  scope :ordered, -> { order(:name) }
  scope :popular, -> { left_joins(:taggings).group(:id).order("COUNT(taggings.id) DESC") }

  # Callbacks
  before_validation :generate_slug, on: :create
  before_validation :normalize_name

  # Instance Methods
  def post_count
    taggings.where(taggable_type: "Post").count
  end

  def usage_count
    taggings.count
  end

  private

  def generate_slug
    return if slug.present? || name.blank?

    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1

    while Tag.exists?(slug: candidate_slug, account_id: account_id)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
