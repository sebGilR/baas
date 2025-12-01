# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Posts::UnpublishPostService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:post) { create(:post, :published, account: account, blog: blog, author: author) }
  let(:service) { described_class.new(post: post, user: author) }

  describe "#call" do
    context "with valid parameters" do
      it "unpublishes the post" do
        result = service.call
        expect(result).to(be_success)
        expect(result.post.status).to(eq("draft"))
        expect(result.post.published_at).to(be_nil)
      end
    end

    context "when post is not published" do
      let(:post) { create(:post, account: account, blog: blog, author: author, status: :draft) }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Post is not published"))
      end
    end

    context "with invalid parameters" do
      context "when post is nil" do
        let(:post) { nil }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("Post is required"))
        end
      end

      context "when user is nil" do
        let(:service) { described_class.new(post: post, user: nil) }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("User is required"))
        end
      end
    end
  end
end
