# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Publishing::Blogs::CreateBlogService) do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:attributes) { { name: "My Tech Blog", description: "A blog about technology" } }
  let(:service) { described_class.new(account: account, user: user, attributes: attributes) }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new blog" do
        expect { service.call }.to(change(Blog, :count).by(1))
      end

      it "returns a successful result" do
        result = service.call
        expect(result).to(be_success)
        expect(result.blog).to(be_a(Blog))
        expect(result.blog.name).to(eq("My Tech Blog"))
        expect(result.blog.description).to(eq("A blog about technology"))
        expect(result.blog.account).to(eq(account))
      end

      it "sets default status to active" do
        result = service.call
        expect(result.blog.status).to(eq("active"))
      end

      it "generates a slug from the name" do
        result = service.call
        expect(result.blog.slug).to(eq("my-tech-blog"))
      end
    end

    context "with custom slug" do
      let(:attributes) { { name: "My Tech Blog", slug: "custom-slug" } }

      it "uses the provided slug" do
        result = service.call
        expect(result.blog.slug).to(eq("custom-slug"))
      end
    end

    context "with invalid parameters" do
      context "when account is nil" do
        let(:account) { nil }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(eq("Account is required"))
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

      context "when name is missing" do
        let(:attributes) { { description: "A blog without a name" } }

        it "returns a failure result" do
          result = service.call
          expect(result).to(be_failure)
          expect(result.errors).to(include("Name can't be blank"))
        end
      end
    end
  end
end
