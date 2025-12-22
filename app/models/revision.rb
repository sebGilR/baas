# frozen_string_literal: true

class Revision < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account

  # Callbacks
  before_validation :sync_legacy_content

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
    plain_text = rich_content_text
    return 0 if plain_text.blank?

    plain_text.split.size
  end

  private

  def rich_content_text
    return content_text if content_text.present?
    return strip_html_content(content_html) if content_html.present?
    return strip_html_content(content) if content.present?

    ""
  end

  def strip_html_content(source)
    source.to_s.gsub(/<[^>]*>/, "").strip
  end

  def sync_legacy_content
    return if content.present?

    self.content = content_html.presence || content_text
  end
end
