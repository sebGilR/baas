# frozen_string_literal: true

require "rails_helper"

# Dummy model for sorting
class SortablePost < ApplicationRecord
  self.table_name = "users" # Use users table for simplicity
end

# Dummy controller to test the concern
class SortableTestController < ApplicationController
  include Sortable

  def index
    scope = SortablePost.all
    sorted_scope = apply_sorting(scope)
    render(json: { ids: sorted_scope.pluck(:id) })
  end

  private

  def allowed_sort_fields
    [:name, :created_at]
  end

  def default_sort
    [{ name: :asc }]
  end
end

RSpec.describe(Sortable, type: :controller) do
  controller(SortableTestController) do
    skip_before_action :authenticate_user!
    class << self
      def controller_path
        "sortable_test"
      end
    end
  end

  let!(:user1) { create(:user, name: "Charlie", created_at: 2.days.ago) }
  let!(:user2) { create(:user, name: "Alice", created_at: 1.day.ago) }
  let!(:user3) { create(:user, name: "Bob", created_at: Time.current) }

  before do
    routes.draw do
      get "index" => "sortable_test#index"
    end
  end

  describe "#apply_sorting" do
    it "sorts by the default sort order if no sort param is given" do
      get :index
      expect(response).to(have_http_status(:ok))
      json = response.parsed_body
      # Default is name: :asc => Alice, Bob, Charlie
      expect(json["ids"]).to(eq([user2.id, user3.id, user1.id]))
    end

    it "sorts by a single allowed field in ascending order" do
      get :index, params: { sort: "created_at" }
      json = response.parsed_body
      expect(json["ids"]).to(eq([user1.id, user2.id, user3.id]))
    end

    it "sorts by a single allowed field in descending order" do
      get :index, params: { sort: "-created_at" }
      json = response.parsed_body
      expect(json["ids"]).to(eq([user3.id, user2.id, user1.id]))
    end

    it "sorts by multiple allowed fields" do
      # Create another user with the same name to test secondary sort
      user4 = create(:user, name: "Alice", created_at: 3.days.ago)
      get :index, params: { sort: "name,-created_at" } # Sort by name asc, then created_at desc
      json = response.parsed_body
      # Alice (recent), Alice (older), Bob, Charlie
      expect(json["ids"]).to(eq([user2.id, user4.id, user3.id, user1.id]))
    end

    it "ignores sort fields that are not in allowed_sort_fields" do
      get :index, params: { sort: "email,-id" } # email and id are not allowed
      json = response.parsed_body
      # Should fall back to default sort (name: :asc)
      expect(json["ids"]).to(eq([user2.id, user3.id, user1.id]))
    end

    it "uses default sort if sort param is empty" do
      get :index, params: { sort: "" }
      json = response.parsed_body
      expect(json["ids"]).to(eq([user2.id, user3.id, user1.id]))
    end
  end
end
