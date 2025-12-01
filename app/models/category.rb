# frozen_string_literal: true

class Category < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :posts

  # Validations
  validates :name, presence: true,
                   length: { minimum: 1, maximum: 100 },
                   uniqueness: { scope: :account_id, case_sensitive: false }
  validates :slug, presence: true,
                   uniqueness: { scope: :account_id },
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validate :parent_cannot_be_self
  validate :parent_cannot_create_cycle

  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }
  scope :with_posts, -> { joins(:posts).distinct }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Instance Methods
  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def ancestors
    result = []
    current = parent
    while current
      result.unshift(current)
      current = current.parent
    end
    result
  end

  def descendants
    result = children.to_a
    children.each do |child|
      result.concat(child.descendants)
    end
    result
  end

  def depth
    ancestors.size
  end

  def full_path
    (ancestors.map(&:name) + [name]).join(" > ")
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

    while Category.exists?(slug: candidate_slug, account_id: account_id)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end

  def parent_cannot_be_self
    return unless parent_id.present? && parent_id == id

    errors.add(:parent_id, "cannot be the category itself")
  end

  def parent_cannot_create_cycle
    return unless parent_id.present?
    return unless persisted?

    if descendants.map(&:id).include?(parent_id)
      errors.add(:parent_id, "cannot create a circular reference")
    end
  end
end
