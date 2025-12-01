# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Blogs::DeleteBlogService) do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:blog) { create(:blog, account: account) }
  let(:service) { described_class.new(blog: blog, user: user) }

  describe "#call" do
    context "with valid parameters" do
      it "marks the blog as deleted (soft delete)" do
        result = service.call
        expect(result).to(be_success)
        expect(result.blog.status).to(eq("deleted"))
      end

      it "does not destroy the blog record" do
        expect { service.call }.not_to(change(Blog, :count))
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
    end
  end
end
