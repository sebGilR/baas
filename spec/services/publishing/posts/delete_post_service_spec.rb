# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Posts::DeletePostService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:post) { create(:post, account: account, blog: blog, author: author) }
  let(:service) { described_class.new(post: post, user: author) }

  describe "#call" do
    context "with valid parameters" do
      it "archives the post (soft delete)" do
        result = service.call
        expect(result).to(be_success)
        expect(result.post.status).to(eq("archived"))
      end

      it "does not destroy the post record" do
        post # Force creation before counting
        expect { service.call }.not_to(change(Post, :count))
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
