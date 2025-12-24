# frozen_string_literal: true

require "json"
require "uri"

module RichContent
  # Minimal renderer for structured editor (Tiptap-like) JSON documents.
  # Converts a limited, allowlisted set of nodes and marks into sanitized HTML.
  class Renderer
    SCHEMA_VERSION = 1

    ALLOWED_BLOCK_NODES = [
      "paragraph",
      "heading",
      "bulletList",
      "orderedList",
      "listItem",
      "blockquote",
      "codeBlock",
      "horizontalRule",
      "hardBreak",
      "image",
    ].freeze

    ALLOWED_MARKS = ["bold", "italic", "underline", "strike", "code", "link"].freeze

    def initialize(document)
      @document = parse_document(document)
    end

    def html
      return "" unless valid_document?

      render_nodes(@document.fetch("content", []))
    end

    def plain_text
      return "" unless valid_document?

      text_from_nodes(@document.fetch("content", []))
    end

    private

    def parse_document(doc)
      case doc
      when String
        JSON.parse(doc)
      when Hash
        doc
      else
        {}
      end
    rescue JSON::ParserError
      {}
    end

    def valid_document?
      @document.present? && @document["type"] == "doc"
    end

    def render_nodes(nodes)
      Array(nodes).map { |node| render_node(node) }.join
    end

    def render_node(node)
      return "" unless node.is_a?(Hash)

      type = node["type"]
      return render_text_node(node) if type == "text"

      if ALLOWED_BLOCK_NODES.exclude?(type)
        return render_nodes(node["content"])
      end

      case type
      when "paragraph"
        wrap("p", render_nodes(node["content"]))
      when "heading"
        level = node.dig("attrs", "level").to_i
        level = 1 if level <= 0
        level = 6 if level > 6
        wrap("h#{level}", render_nodes(node["content"]))
      when "bulletList"
        wrap("ul", render_nodes(node["content"]))
      when "orderedList"
        start = node.dig("attrs", "start")
        attrs = start.present? ? { start: start } : {}
        wrap("ol", render_nodes(node["content"]), attrs)
      when "listItem"
        wrap("li", render_nodes(node["content"]))
      when "blockquote"
        wrap("blockquote", render_nodes(node["content"]))
      when "codeBlock"
        wrap("pre", wrap("code", render_textual_children(node)))
      when "horizontalRule"
        "<hr />"
      when "hardBreak"
        "<br />"
      when "image"
        render_image(node)
      else
        render_nodes(node["content"])
      end
    end

    def render_image(node)
      src = safe_url(node.dig("attrs", "src"))
      return "" if src.blank?

      alt = ERB::Util.html_escape(node.dig("attrs", "alt").to_s)
      title = ERB::Util.html_escape(node.dig("attrs", "title").to_s)
      attributes = { src:, alt: }
      attributes[:title] = title if title.present?

      wrap("figure", wrap("img", "", attributes, void: true))
    end

    def render_text_node(node)
      text = ERB::Util.html_escape(node["text"].to_s)
      Array(node["marks"]).reduce(text) do |memo, mark|
        apply_mark(memo, mark)
      end
    end

    def apply_mark(content, mark)
      return content unless mark.is_a?(Hash)

      type = mark["type"]
      return content if ALLOWED_MARKS.exclude?(type)

      case type
      when "bold"
        wrap("strong", content)
      when "italic"
        wrap("em", content)
      when "underline"
        wrap("u", content)
      when "strike"
        wrap("s", content)
      when "code"
        wrap("code", content)
      when "link"
        href = safe_url(mark.dig("attrs", "href"))
        return content if href.blank?

        attrs = { href:, target: "_blank", rel: "noopener noreferrer" }
        wrap("a", content, attrs)
      else
        content
      end
    end

    def render_textual_children(node)
      text_from_nodes(node.fetch("content", []))
    end

    def text_from_nodes(nodes)
      Array(nodes).map { |child| text_from_node(child) }.join
    end

    def text_from_node(node)
      return "" unless node.is_a?(Hash)

      case node["type"]
      when "text"
        node["text"].to_s
      when "hardBreak"
        "\n"
      else
        text_from_nodes(node["content"])
      end
    end

    def safe_url(url)
      return if url.blank?

      uri = URI.parse(url)
      url if ["http", "https", "mailto"].include?(uri.scheme)
    rescue URI::InvalidURIError
      nil
    end

    def wrap(tag, content, attrs = {}, void: false)
      attr_string = attrs.compact.map do |key, value|
        next if value.blank?

        %(#{key}="#{ERB::Util.html_escape(value.to_s)}")
      end.compact.join(" ")
      attr_string = " #{attr_string}" if attr_string.present?

      if void
        "<#{tag}#{attr_string} />"
      else
        "<#{tag}#{attr_string}>#{content}</#{tag}>"
      end
    end
  end
end
