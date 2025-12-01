# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Drafts::CreateDraftService) do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  let(:user) { create(:user) }
  let(:attributes) { { title: "Draft Title", content: "Draft content" } }
  let(:service) { described_class.new(account: account, blog: blog, user: user, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new draft" do
        expect { service.call }.to(change(Draft, :count).by(1))
      end

      it "returns a successful result" do
        result = service.call
        expect(result).to(be_success)
        expect(result.draft).to(be_a(Draft))
        expect(result.draft.title).to(eq("Draft Title"))
        expect(result.draft.content).to(eq("Draft content"))
      end

      it "assigns the user as author" do
        result = service.call
        expect(result.draft.author).to(eq(user))
      end

      it "sets autosaved_at" do
        result = service.call
        expect(result.draft.autosaved_at).to(be_present)
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
    end
  end
end
