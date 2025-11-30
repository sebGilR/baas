# frozen_string_literal: true

require "rails_helper"

# Dummy controller to test the concern
class PaginatableTestController < ApplicationController
  include Paginatable

  def index
    # Using User as a dummy model with some records
    scope = User.all
    paginated_scope = paginate(scope)
    render(json: {
      meta: pagination_meta(paginated_scope),
      links: pagination_links(paginated_scope),
    })
  end
end

RSpec.describe(Paginatable, type: :controller) do
  controller(PaginatableTestController) do
    class << self
      def controller_path
        "paginatable_test"
      end
    end
  end

  before do
    routes.draw do
      get "index" => "paginatable_test#index"
    end
    # Create some data to paginate
    create_list(:user, 25)
  end

  describe "pagination logic" do
    it "paginates with default settings" do
      get :index
      expect(response).to(have_http_status(:ok))
      json = response.parsed_body

      expect(json["meta"]["current_page"]).to(eq(1))
      expect(json["meta"]["page_size"]).to(eq(20)) # Paginatable::DEFAULT_PAGE_SIZE
      expect(json["meta"]["total_pages"]).to(eq(2))
      expect(json["meta"]["total_count"]).to(eq(25))
    end

    it "respects page number and size parameters" do
      get :index, params: { page: { number: 2, size: 10 } }
      expect(response).to(have_http_status(:ok))
      json = response.parsed_body

      expect(json["meta"]["current_page"]).to(eq(2))
      expect(json["meta"]["page_size"]).to(eq(10))
      expect(json["meta"]["total_pages"]).to(eq(3))
      expect(json["meta"]["total_count"]).to(eq(25))
    end

    it "caps page size at MAX_PAGE_SIZE" do
      get :index, params: { page: { size: 200 } } # Paginatable::MAX_PAGE_SIZE is 100
      expect(response).to(have_http_status(:ok))
      json = response.parsed_body
      expect(json["meta"]["page_size"]).to(eq(100))
    end
  end

  describe "#pagination_links" do
    it "generates correct links for the first page" do
      get :index, params: { page: { number: 1, size: 10 } }
      json = response.parsed_body
      links = json["links"]

      expect(links["self"]).to(eq("/index?page[number]=1&page[size]=10"))
      expect(links["first"]).to(eq("/index?page[number]=1&page[size]=10"))
      expect(links["last"]).to(eq("/index?page[number]=3&page[size]=10"))
      expect(links["next"]).to(eq("/index?page[number]=2&page[size]=10"))
      expect(links).not_to(have_key("prev"))
    end

    it "generates correct links for a middle page" do
      get :index, params: { page: { number: 2, size: 10 } }
      json = response.parsed_body
      links = json["links"]

      expect(links["self"]).to(eq("/index?page[number]=2&page[size]=10"))
      expect(links["first"]).to(eq("/index?page[number]=1&page[size]=10"))
      expect(links["last"]).to(eq("/index?page[number]=3&page[size]=10"))
      expect(links["next"]).to(eq("/index?page[number]=3&page[size]=10"))
      expect(links["prev"]).to(eq("/index?page[number]=1&page[size]=10"))
    end

    it "generates correct links for the last page" do
      get :index, params: { page: { number: 3, size: 10 } }
      json = response.parsed_body
      links = json["links"]

      expect(links["self"]).to(eq("/index?page[number]=3&page[size]=10"))
      expect(links["first"]).to(eq("/index?page[number]=1&page[size]=10"))
      expect(links["last"]).to(eq("/index?page[number]=3&page[size]=10"))
      expect(links["prev"]).to(eq("/index?page[number]=2&page[size]=10"))
      expect(links).not_to(have_key("next"))
    end
  end
end
