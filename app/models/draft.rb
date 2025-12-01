# frozen_string_literal: true

class Draft < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  belongs_to :blog
  belongs_to :author, class_name: "User"
  belongs_to :post, optional: true # Optional link to existing post for editing
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # Validations
  validates :title, length: { maximum: 255 }, allow_blank: true

  # Scopes
  scope :ordered, -> { order(updated_at: :desc) }
  scope :recent, -> { where("updated_at > ?", 24.hours.ago) }
  scope :by_author, ->(author_id) { where(author_id: author_id) }
  scope :by_blog, ->(blog_id) { where(blog_id: blog_id) }

  # Instance Methods
  def autosave!(content:, title: nil)
    update!(
      content: content,
      title: title || self.title,
      autosaved_at: Time.current
    )
  end

  def convert_to_post!
    return nil if title.blank? || content.blank?

    Post.create!(
      account: account,
      blog: blog,
      author: author,
      title: title,
      content: content,
      status: :draft,
      metadata: metadata
    ).tap do |new_post|
      # Copy tags to the new post
      tags.each do |tag|
        new_post.taggings.create!(account: account, tag: tag)
      end
      # Delete the draft after successful conversion
      destroy!
    end
  end

  def word_count
    return 0 if content.blank?

    content.gsub(/<[^>]*>/, "").split.size
  end

  def last_saved
    autosaved_at || updated_at
  end
end
