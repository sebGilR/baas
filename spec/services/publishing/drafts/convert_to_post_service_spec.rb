# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Drafts::ConvertToPostService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:draft) { create(:draft, account: account, blog: blog, author: author, title: "Draft Title", content: "Draft content") }
  let(:service) { described_class.new(draft: draft, user: author) }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new post from the draft" do
        draft # Force creation before counting
        expect { service.call }.to(change(Post, :count).by(1))
      end

      it "deletes the draft after conversion" do
        draft # Force creation before counting
        expect { service.call }.to(change(Draft, :count).by(-1))
      end

      it "returns a successful result with the post" do
        result = service.call
        expect(result).to(be_success)
        expect(result.post.title).to(eq("Draft Title"))
        expect(result.post.content).to(eq("Draft content"))
      end

      it "creates the post with draft status" do
        result = service.call
        expect(result.post.status).to(eq("draft"))
      end
    end

    context "when draft has no title" do
      let(:draft) { create(:draft, account: account, blog: blog, author: author, title: nil, content: "Content") }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Draft must have a title"))
      end
    end

    context "when draft has no content" do
      let(:draft) { create(:draft, account: account, blog: blog, author: author, title: "Title", content: nil) }

      it "returns a failure result" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).to(eq("Draft must have content"))
      end
    end

    context "with invalid parameters" do
      context "when draft is nil" do
        let(:draft) { nil }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("Draft is required"))
        end
      end

      context "when user is nil" do
        let(:service) { described_class.new(draft: draft, user: nil) }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("User is required"))
        end
      end
    end
  end
end
