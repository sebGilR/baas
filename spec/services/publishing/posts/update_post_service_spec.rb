# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Posts::UpdatePostService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:post) { create(:post, account: account, blog: blog, author: author, title: "Original Title", content: "Original content") }
  let(:attributes) { { title: "Updated Title", content: "Updated content" } }
  let(:service) { described_class.new(post: post, user: author, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "updates the post" do
        result = service.call
        expect(result).to(be_success)
        expect(result.post.title).to(eq("Updated Title"))
        expect(result.post.content).to(eq("Updated content"))
      end

      it "creates a revision when content changes" do
        expect { service.call }.to(change(Revision, :count).by(1))
      end

      it "does not create a revision when content is unchanged" do
        service = described_class.new(post: post, user: author, attributes: { title: "New Title" })
        expect { service.call }.not_to(change(Revision, :count))
      end
    end

    context "with tags" do
      let(:tag1) { create(:tag, account: account) }
      let(:tag2) { create(:tag, account: account) }
      let(:attributes) { { tag_ids: [tag1.public_id, tag2.public_id] } }

      it "updates tags" do
        result = service.call
        expect(result.post.tags).to(include(tag1, tag2))
      end

      it "replaces existing tags" do
        old_tag = create(:tag, account: account)
        create(:tagging, tag: old_tag, taggable: post, account: account)

        result = service.call
        expect(result.post.tags).not_to(include(old_tag))
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
        let(:service) { described_class.new(post: post, user: nil, attributes: attributes) }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("User is required"))
        end
      end

      context "when title is cleared" do
        let(:attributes) { { title: "" } }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(include("Title can't be blank"))
        end
      end
    end
  end
end
