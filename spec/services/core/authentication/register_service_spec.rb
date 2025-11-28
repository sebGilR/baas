# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Core::Authentication::RegisterService) do
  let(:email) { "user@example.com" }
  let(:password) { "Password123!" }
  let(:name) { "John Doe" }
  let(:account_name) { "My Awesome Company" }
  let(:service) do
    described_class.new(
      email: email,
      password: password,
      name: name,
      account_name: account_name,
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "creates a new user, account, and membership" do
        expect { service.call }.to(change(User, :count).by(1)
          .and(change(Account, :count).by(1)
          .and(change(
            AccountMembership,
            :count,
          ).by(1))))
      end

      it "returns a successful result with tokens" do
        result = service.call
        expect(result).to(be_success)
        expect(result.data.user).to(be_a(User))
        expect(result.data.account).to(be_a(Account))
        expect(result.data.access_token).to(be_a(String))
        expect(result.data.refresh_token).to(be_a(String))
        expect(result.data.expires_in).to(eq(1800))
      end

      it "assigns the correct attributes to the new records" do
        result = service.call
        user = result.data.user
        account = result.data.account
        membership = user.account_memberships.first

        expect(user.email).to(eq(email))
        expect(user.name).to(eq(name))
        expect(account.name).to(eq(account_name))
        expect(membership.role).to(eq("owner"))
        expect(membership.status).to(eq("active"))
      end

      context "when account name is not provided" do
        let(:service) { described_class.new(email: email, password: password, name: name) }

        it "defaults the account name to 'John Doe's Account'" do
          result = service.call
          expect(result.data.account.name).to(eq("John Doe's Account"))
        end
      end
    end

    context "with invalid parameters" do
      let(:email) { "invalid" }

      it "does not create any records" do
        expect { service.call }.not_to(change(User, :count))
        expect { service.call }.not_to(change(Account, :count))
        expect { service.call }.not_to(change(AccountMembership, :count))
      end

      it "returns a failure result with errors" do
        result = service.call
        expect(result).to(be_failure)
        expect(result.errors).not_to(be_empty)
      end
    end
  end
end
