# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Posts::PublishPostService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:post) { create(:post, account: account, blog: blog, author: author, content: "Test content") }
  let(:service) { described_class.new(post: post, user: author) }

  describe "#call" do
    context "with valid parameters" do
      it "publishes the post" do
        result = service.call
        expect(result).to(be_success)
        expect(result.post.status).to(eq("published"))
        expect(result.post.published_at).to(be_present)
      end

      it "creates a revision before publishing" do
        expect { service.call }.to(change(Revision, :count).by(1))
      end
    end

    context "when post cannot be published" do
      let(:post) { create(:post, account: account, blog: blog, author: author, content: nil) }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Post cannot be published without content"))
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
