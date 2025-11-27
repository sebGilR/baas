# frozen_string_literal: true

class Account < ApplicationRecord
  include PublicIdentifiable

  # Associations
  has_many :account_memberships, dependent: :destroy
  has_many :users, through: :account_memberships

  # Validations
  validates :name, presence: true, length: { minimum: 2 }
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }

  # Enums
  enum :status, { active: 0, suspended: 1, deleted: 2 }, prefix: true
  enum :plan, { free: 0, pro: 1, team: 2 }, prefix: true

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :active, -> { where(status: :active) }

  private

  def generate_slug
    return if slug.present? || name.blank?

    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1

    while Account.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
