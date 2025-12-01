# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Blogs::UpdateBlogService) do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:blog) { create(:blog, account: account, name: "Original Name") }
  let(:attributes) { { name: "Updated Name", description: "New description" } }
  let(:service) { described_class.new(blog: blog, user: user, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "updates the blog" do
        result = service.call
        expect(result).to(be_success)
        expect(result.blog.name).to(eq("Updated Name"))
        expect(result.blog.description).to(eq("New description"))
      end

      it "does not change the account" do
        result = service.call
        expect(result.blog.account).to(eq(account))
      end
    end

    context "with invalid parameters" do
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

      context "when name is empty" do
        let(:attributes) { { name: "" } }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(include("Name can't be blank"))
        end
      end
    end
  end
end
