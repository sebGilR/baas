# frozen_string_literal: true

class Revision < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Associations
  belongs_to :account
  belongs_to :post
  belongs_to :created_by, class_name: "User"

  # Validations
  validates :title, presence: true
  validates :revision_number, presence: true,
                              uniqueness: { scope: [:account_id, :post_id] },
                              numericality: { only_integer: true, greater_than: 0 }

  # Scopes
  scope :ordered, -> { order(revision_number: :desc) }
  scope :latest, -> { order(revision_number: :desc).first }
  scope :by_post, ->(post_id) { where(post_id: post_id) }

  # Instance Methods
  def restore!
    post.update!(
      title: title,
      content: content
    )
  end

  def diff_from_current
    {
      title_changed: title != post.title,
      content_changed: content != post.content,
      current_title: post.title,
      current_content: post.content,
      revision_title: title,
      revision_content: content
    }
  end

  def word_count
    return 0 if content.blank?

    content.gsub(/<[^>]*>/, "").split.size
  end
end
