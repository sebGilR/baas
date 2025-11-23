# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1 routes
  namespace :api do
    namespace :v1 do
      # Health check endpoint
      get "health", to: "health#show"

      # Authentication routes
      post "auth/login", to: "authentication#login"
      post "auth/register", to: "authentication#register"
      post "auth/refresh", to: "authentication#refresh"
      post "auth/logout", to: "authentication#logout"
      post "auth/switch_account", to: "authentication#switch_account"

      # Core resources
      resources :accounts, only: %i[index show create update]
      resources :users, only: %i[index show update]

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
        end
      end

      # Analytics resources
      namespace :analytics do
        get "dashboard", to: "dashboard#show"
        resources :reports, only: %i[index show]
      end
    end
  end
end
