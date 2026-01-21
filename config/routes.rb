# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Authentication
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root - Landing page for visitors, dashboard for logged-in users
  root "pages#home"

  # Legal pages
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Company settings
  resource :company, only: [:show, :edit, :create, :update] do
    delete :remove_logo, on: :member
  end

  # Clients
  resources :clients do
    member do
      post :regenerate_magic_link
    end
    collection do
      get :search
    end
  end

  # Quotes (estimates before signing)
  resources :quotes do
    member do
      post :send_to_client
      post :duplicate
      get :preview_pdf
      get :download_pdf
    end

    # Line items nested under quotes
    resources :line_items, only: [:create, :update, :destroy] do
      collection do
        post :reorder
      end
    end

    # Legacy change orders route (redirect to job)
    resources :change_orders, only: [:index, :show]
  end

  # Jobs (active projects after quote is signed)
  resources :jobs, only: [:index, :show, :edit, :update] do
    member do
      post :start
      post :complete
      post :hold
      post :resume
    end

    # Change orders are now nested under jobs
    resources :change_orders do
      member do
        post :send_to_client
        get :preview_pdf
        get :download_pdf
        get :signature
        post :submit_signature
      end
    end
  end

  # Voice sessions
  resources :voice_sessions, only: [:create, :show] do
    member do
      post :process_audio
    end
  end

  # Client Portal (magic link access - no auth required)
  namespace :portal do
    # Quote portal (for unsigned quotes)
    get "quote/:token", to: "quotes#show", as: :quote
    post "quote/:token/sign", to: "quotes#sign", as: :sign_quote

    # Job portal (for active jobs)
    get "job/:token", to: "jobs#show", as: :job
    
    # Change order portal
    get "change_order/:token", to: "change_orders#show", as: :change_order
    get "change_order/:token/signature", to: "change_orders#signature", as: :change_order_signature
    post "change_order/:token/sign", to: "change_orders#sign", as: :sign_change_order
  end

  # API endpoints for voice and AI processing
  namespace :api do
    namespace :v1 do
      resources :voice_sessions, only: [:create, :update] do
        member do
          post :transcribe
          post :extract
        end
      end

      resources :quotes, only: [] do
        member do
          post :generate_from_voice
        end
      end

      resources :change_orders, only: [] do
        member do
          post :generate_from_voice
        end
      end
    end
  end

  # Admin
  namespace :admin do
    resources :users, only: [:index, :show]
  end

  # Sidekiq Web UI (admin only)
  require "sidekiq/web"
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end
end
