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
  scope :by_blog, lambda { |identifier|
    if identifier.is_a?(Blog)
      where(blog: identifier)
    elsif identifier.to_s.match?(/\A\d+\z/)
      where(blog_id: identifier)
    else
      joins(:blog).where(blogs: { public_id: identifier })
    end
  }

  # Callbacks
  before_validation :clear_rich_content_if_cleared
  before_validation :sync_legacy_content
  before_validation :generate_rich_content_artifacts, if: :rich_content_needs_refresh?

  # Instance Methods
  def autosave!(title: nil, content: nil, content_json: nil, content_html: nil, content_text: nil)
    self.title = title || self.title
    self.content = content unless content.nil?
    self.content_json = content_json unless content_json.nil?
    self.content_html = content_html unless content_html.nil?
    self.content_text = content_text unless content_text.nil?
    self.autosaved_at = Time.current
    RichContent::ArtifactPipeline.apply(self)
    save!
  end

  def convert_to_post!
    return if title.blank? || !rich_content_present?

    new_post = nil
    ActiveRecord::Base.transaction do
      new_post = Post.new(
        account: account,
        blog: blog,
        author: author,
        title: title,
        content: legacy_content_value,
        content_json: content_json,
        content_html: content_html,
        content_text: content_text,
        status: :draft,
        metadata:,
      )
      RichContent::ArtifactPipeline.apply(new_post)
      new_post.save!

      # Copy tags to the new post
      tags.each do |tag|
        new_post.taggings.create!(account: account, tag: tag)
      end

      # Delete the draft after successful conversion
      destroy!
    end

    new_post
  end

  def word_count
    plain_text = rich_content_text
    return 0 if plain_text.blank?

    plain_text.split.size
  end

  def last_saved
    autosaved_at || updated_at
  end

  def rich_content_present?
    content.present? || content_json.present? || content_html.present? || content_text.present?
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

  def legacy_content_value
    content.presence || content_html.presence || content_text
  end

  def sync_legacy_content
    return if content.present?

    self.content = content_html.presence || content_text
  end

  def clear_rich_content_if_cleared
    return unless will_save_change_to_attribute?(:content)
    return if content.present?
    return if content_json.present?

    self.content_html = nil
    self.content_text = nil
  end

  def rich_content_needs_refresh?
    new_record? ||
      will_save_change_to_attribute?(:content_json) ||
      will_save_change_to_attribute?(:content_html) ||
      will_save_change_to_attribute?(:content_text) ||
      will_save_change_to_attribute?(:content)
  end

  def generate_rich_content_artifacts
    RichContent::ArtifactPipeline.apply(self)
  end
end
