# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Drafts::AutosaveDraftService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:draft) { create(:draft, account: account, blog: blog, author: author) }
  let(:content) { "Updated content" }
  let(:title) { "Updated title" }
  let(:attributes) { { content: content, title: title } }
  let(:service) { described_class.new(draft: draft, user: author, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "updates the draft content" do
        result = service.call
        expect(result).to(be_success)
        expect(result.draft.content).to(eq("Updated content"))
        expect(result.draft.title).to(eq("Updated title"))
      end

      context "with only structured content" do
        let(:content_json) { { "type" => "doc", "content" => [] } }
        let(:attributes) { { content_json: content_json } }

        it "updates content_json without touching the legacy content field" do
          original_content = draft.content
          result = service.call
          expect(result).to(be_success)
          expect(result.draft.content_json).to(eq(content_json))
          expect(result.draft.content).to(eq(original_content))
        end
      end

      it "updates autosaved_at" do
        original_autosaved_at = draft.autosaved_at
        sleep 1
        service.call
        draft.reload
        expect(draft.autosaved_at).to(be > original_autosaved_at)
      end
    end

    context "with only content" do
      let(:attributes) { { content: content } }

      it "preserves the original title" do
        original_title = draft.title
        result = service.call
        expect(result.draft.title).to(eq(original_title))
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
        let(:service) { described_class.new(draft: draft, user: nil, attributes: attributes) }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("User is required"))
        end
      end

      context "when no content attributes are provided" do
        let(:attributes) { { title: "Only title" } }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("Content is required"))
        end
      end
    end
  end
end
