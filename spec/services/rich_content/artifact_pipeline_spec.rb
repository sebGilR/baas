# frozen_string_literal: true

require "rails_helper"

RSpec.describe(RichContent::ArtifactPipeline) do
  describe ".apply" do
    it "generates sanitized artifacts from structured content" do
      post = build(:post, content: nil, content_html: nil, content_text: nil)
      post.content_json = {
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Hello", "marks" => [{ "type" => "bold" }] },
              { "type" => "text", "text" => " world" },
            ],
          },
        ],
      }

      described_class.apply(post)

      expect(post.content_html).to(eq("<p><strong>Hello</strong> world</p>"))
      expect(post.content_text).to(eq("Hello world"))
      expect(post.content_schema_version).to(eq(RichContent::Renderer::SCHEMA_VERSION))
    end

    it "removes unsafe tags when HTML is provided" do
      post = build(:post, content_json: nil, content_text: nil)
      post.content_html = "<p>Hello<script>alert('xss')</script></p>"

      described_class.apply(post)

      expect(post.content_html).to(eq("<p>Hello</p>"))
      expect(post.content_text).to(eq("Hello"))
    end
  end
end
