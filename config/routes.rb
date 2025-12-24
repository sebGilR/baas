# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1 routes
  namespace :api do
    namespace :v1 do
      # Health check endpoint
      get "health", to: "health#show"
      get "public", to: "public#show"

      namespace :public do
        resources :blogs, only: [:show], param: :slug do
          resources :posts, only: [:index, :show], param: :slug
        end
      end

      # Authentication routes
      namespace :auth do
        post "register", to: "registrations#create"
        post "login", to: "sessions#create"
        post "refresh", to: "refresh_tokens#create"
        delete "logout", to: "refresh_tokens#destroy"
      end

      # Core resources
      resources :api_keys, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :revoke
        end
      end

      # Publishing resources
      resources :blogs
      resources :posts do
        member do
          post :publish
          post :unpublish
        end
      end
      resources :drafts do
        member do
          post :autosave
          post :convert_to_post
        end
      end
      resources :tags
      resources :categories
    end
  end
end
