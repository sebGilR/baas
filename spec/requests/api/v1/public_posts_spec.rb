# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Public posts API", type: :request) do
  describe "GET /api/v1/public/blogs/:blog_slug/posts/:slug" do
    it "returns the published post without authentication" do
      blog = create(:blog, slug: "engineering")
      post = create(:post, :published, blog:, account: blog.account, slug: "hello-world", content_html: "<p>Hello</p>", content_text: "Hello")

      get "/api/v1/public/blogs/#{blog.slug}/posts/#{post.slug}"

      expect(response).to(have_http_status(:ok))
      body = response.parsed_body
      expect(body.dig("data", "id")).to(eq(post.slug))
      expect(body.dig("data", "attributes", "content_html")).to(eq("<p>Hello</p>"))
    end
  end

  describe "GET /api/v1/public/blogs/:blog_slug/posts" do
    it "paginates published posts" do
      blog = create(:blog, slug: "engineering")
      create_list(:post, 2, :published, blog:, account: blog.account)

      get "/api/v1/public/blogs/#{blog.slug}/posts"

      expect(response).to(have_http_status(:ok))
      body = response.parsed_body
      expect(body.dig("data").size).to(eq(2))
      expect(body.dig("meta", "current_page")).to(eq(1))
    end
  end
end
