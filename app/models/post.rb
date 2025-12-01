# frozen_string_literal: true

class Post < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  belongs_to :blog
  belongs_to :author, class_name: "User"
  belongs_to :category, optional: true
  has_many :revisions, dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :slug, presence: true,
                   uniqueness: { scope: :account_id, message: "has already been taken for this account" },
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :content, presence: true, on: :publish

  # Enums
  enum :status, { draft: 0, published: 1, scheduled: 2, archived: 3 }, prefix: true

  # Scopes
  scope :published, -> { where(status: :published).where("published_at <= ?", Time.current) }
  scope :scheduled, -> { where(status: :scheduled).where("scheduled_for > ?", Time.current) }
  scope :drafts, -> { where(status: :draft) }
  scope :featured, -> { where(featured: true) }
  scope :by_blog, ->(blog_id) { where(blog_id: blog_id) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_published_date, -> { order(published_at: :desc) }

  # Callbacks
  before_validation :generate_slug, on: :create
  before_save :calculate_reading_time
  before_save :set_excerpt

  # Instance Methods
  def publish!
    return false unless can_publish?

    update!(
      status: :published,
      published_at: Time.current
    )
  end

  def unpublish!
    update!(
      status: :draft,
      published_at: nil
    )
  end

  def schedule!(scheduled_time)
    return false if scheduled_time <= Time.current

    update!(
      status: :scheduled,
      scheduled_for: scheduled_time
    )
  end

  def published?
    status_published? && published_at&.past?
  end

  def can_publish?
    title.present? && content.present?
  end

  def create_revision!(user)
    revisions.create!(
      account: account,
      title: title,
      content: content,
      revision_number: next_revision_number,
      created_by: user
    )
  end

  private

  def generate_slug
    return if slug.present? || title.blank?

    base_slug = title.parameterize
    candidate_slug = base_slug
    counter = 1

    while Post.exists?(slug: candidate_slug, account_id: account_id)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end

  def calculate_reading_time
    return unless content.present?

    words_per_minute = 200
    word_count = content.split.size
    self.reading_time_minutes = [(word_count / words_per_minute.to_f).ceil, 1].max
  end

  def set_excerpt
    return if excerpt.present? || content.blank?

    # Extract first 160 characters of content, stripping HTML
    plain_text = content.gsub(/<[^>]*>/, "").strip
    self.excerpt = plain_text.truncate(160)
  end

  def next_revision_number
    (revisions.maximum(:revision_number) || 0) + 1
  end
end
