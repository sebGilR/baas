# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Posts::CreatePostService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:user) { create(:user) }
  let(:attributes) { { title: "My First Post", content: "This is the content" } }
  let(:service) { described_class.new(account: account, blog: blog, user: user, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new post" do
        expect { service.call }.to(change(Post, :count).by(1))
      end

      it "returns a successful result" do
        result = service.call
        expect(result).to(be_success)
        expect(result.post).to(be_a(Post))
        expect(result.post.title).to(eq("My First Post"))
        expect(result.post.content).to(eq("This is the content"))
      end

      it "sets default status to draft" do
        result = service.call
        expect(result.post.status).to(eq("draft"))
      end

      it "generates a slug from the title" do
        result = service.call
        expect(result.post.slug).to(eq("my-first-post"))
      end

      it "assigns the user as author" do
        result = service.call
        expect(result.post.author).to(eq(user))
      end
    end

    context "with tags" do
      let(:tag1) { create(:tag, account: account) }
      let(:tag2) { create(:tag, account: account) }
      let(:attributes) { { title: "My First Post", content: "Content", tag_ids: [tag1.public_id, tag2.public_id] } }

      it "assigns tags to the post" do
        result = service.call
        expect(result.post.tags).to(include(tag1, tag2))
      end
    end

    context "with invalid parameters" do
      context "when account is nil" do
        let(:account) { nil }
        let(:blog) { create(:blog) }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("Account is required"))
        end
      end

      context "when blog is nil" do
        let(:blog) { nil }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("Blog is required"))
        end
      end

      context "when user is nil" do
        let(:user) { nil }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("User is required"))
        end
      end

      context "when title is missing" do
        let(:attributes) { { content: "Content without title" } }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(include("Title can't be blank"))
        end
      end
    end
  end
end
