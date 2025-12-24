# frozen_string_literal: true

require "json"

module RichContent
  # Generates sanitized HTML/text artifacts from structured editor payloads.
  class ArtifactPipeline
    SAFE_LIST_TAGS = [
      "p", "strong", "em", "code", "u", "s", "a", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "li", "blockquote", "pre", "hr", "img", "figure", "br",
    ].freeze
    SAFE_LIST_ATTRIBUTES = ["href", "rel", "target", "alt", "title", "src", "start"].freeze

    class << self
      def apply(record, source_attributes = {})
        new(record, source_attributes).apply
      end
    end

    def initialize(record, source_attributes = {})
      @record = record
      @source_attributes = default_sources.merge(source_attributes.symbolize_keys)
      @document = nil
    end

    def apply
      artifacts = build_artifacts
      return if artifacts.blank?

      record.assign_attributes(artifacts)
    end

    private

    attr_reader :record, :source_attributes

    def default_sources
      {
        content_json: record.try(:content_json),
        content_html: record.try(:content_html),
        content_text: record.try(:content_text),
        legacy_content: record.try(:content),
      }.compact
    end

    def build_artifacts
      html = nil
      text = nil
      schema_version = nil

      if content_json.present?
        renderer = RichContent::Renderer.new(content_json)
        html = sanitize(renderer.html)
        text = renderer.plain_text
        schema_version = RichContent::Renderer::SCHEMA_VERSION
        @document = renderer
      elsif content_html.present?
        html = sanitize(content_html)
        text = plain_text(html)
      elsif content_text.present?
        text = content_text.to_s
        html = wrap_plain_text(text)
      elsif legacy_content.present?
        html = sanitize(legacy_content)
        text = plain_text(html)
      end

      return if html.blank? && text.blank?

      html = wrap_plain_text(text) if html.blank? && text.present?

      {
        content_json: normalized_content_json,
        content_html: html,
        content_text: text,
        content_schema_version: schema_version || record.try(:content_schema_version) || RichContent::Renderer::SCHEMA_VERSION,
      }
    end

    def normalized_content_json
      return content_json if content_json.is_a?(Hash)
      return JSON.parse(content_json) if content_json.is_a?(String)

      record.try(:content_json)
    rescue JSON::ParserError
      record.try(:content_json)
    end

    def sanitize(html)
      return "" if html.blank?

      stripped = html.gsub(%r{<script.*?>.*?</script>}im, "")
      sanitizer.sanitize(
        stripped,
        tags: SAFE_LIST_TAGS,
        attributes: SAFE_LIST_ATTRIBUTES,
      ).to_s
    end

    def sanitizer
      @sanitizer ||= Rails::Html::SafeListSanitizer.new
    end

    def plain_text(html)
      ActionView::Base.full_sanitizer.sanitize(html).to_s.gsub(/\s+/, " ").strip
    end

    def wrap_plain_text(text)
      paragraphs = text.to_s.split(/\n{2,}/).map do |segment|
        "<p>#{ERB::Util.html_escape(segment.strip)}</p>"
      end
      paragraphs.join
    end

    def content_json
      source_attributes[:content_json]
    end

    def content_html
      source_attributes[:content_html]
    end

    def content_text
      source_attributes[:content_text]
    end

    def legacy_content
      source_attributes[:legacy_content]
    end
  end
end
