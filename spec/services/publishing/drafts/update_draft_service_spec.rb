# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Drafts::UpdateDraftService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:draft) { create(:draft, account: account, blog: blog, author: author, title: "Original Title") }
  let(:attributes) { { title: "Updated Title", content: "Updated content" } }
  let(:service) { described_class.new(draft: draft, user: author, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "updates the draft" do
        result = service.call
        expect(result).to(be_success)
        expect(result.draft.title).to(eq("Updated Title"))
        expect(result.draft.content).to(eq("Updated content"))
      end

      it "updates autosaved_at" do
        original_autosaved_at = draft.autosaved_at
        sleep 1
        result = service.call
        expect(result.draft.autosaved_at).to(be > original_autosaved_at)
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
    end
  end
end
