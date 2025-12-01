# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Drafts::DeleteDraftService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:author) { create(:user) }
  let(:draft) { create(:draft, account: account, blog: blog, author: author) }
  let(:service) { described_class.new(draft: draft, user: author) }

  describe "#call" do
    context "with valid parameters" do
      it "deletes the draft" do
        draft # Force creation before counting
        expect { service.call }.to(change(Draft, :count).by(-1))
      end

      it "returns a successful result" do
        result = service.call
        expect(result).to(be_success)
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
