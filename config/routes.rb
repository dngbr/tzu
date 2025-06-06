require 'sidekiq/web'

Rails.application.routes.draw do
  # Public website routes
  root "home#index"
  get "home/index"
  
  # Authentication routes with my_account prefix
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }, path: 'my_account', path_names: {
    sign_in: 'login',
    sign_up: 'signup',
    sign_out: 'logout'
  }
  
  # Public company review routes
  get 'review_company', to: 'my_account/company_reviews#new'
  post 'review_company', to: 'my_account/company_reviews#create'
  get 'company_reviews/:id', to: 'my_account/company_reviews#show', as: :company_review
  
  # Public company routes
  resources :companies, only: [:show]
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Business platform routes (my_account namespace)
  namespace :my_account do
    # Use dashboard as the root of my_account
    get '/', to: 'dashboard#index', as: :root
    
    # Company management
    resources :companies, only: [:new, :create, :edit, :update]
    get 'my_company', to: 'companies#my_company', as: :my_company
    post 'switch_company', to: 'company_switcher#switch', as: :switch_company
    
    # Reviews management
    get 'my_reviews', to: 'company_reviews#index', as: :my_reviews
    post 'analyze_reviews', to: 'company_reviews#analyze', as: :analyze_reviews
    get 'check_analysis_status', to: 'company_reviews#check_analysis_status', as: :check_analysis_status
    get 'company_reviews/:id', to: 'company_reviews#show', as: :company_review
    
    # Notifications
    resources :notifications, only: [:index, :show] do
      post :mark_as_read, on: :member
      collection do
        post :mark_all_as_read
      end
    end
    
    # Profile management
    get 'profile', to: 'profiles#show', as: :profile
    get 'my_profile', to: 'profiles#my_profile', as: :my_profile
    patch 'update_profile', to: 'profiles#update', as: :update_profile
    patch 'update_password', to: 'profiles#update_password', as: :update_password
    
    # CSV Upload routes
    resources :csv_uploads, only: [:new, :create, :index, :show]
    get 'my_uploads', to: 'csv_uploads#my_uploads', as: :my_uploads
    
    # Analysis routes
    resources :analyses, only: [:show]
  end
  
  # Sidekiq web UI - only accessible by business owners
  authenticate :user, lambda { |u| u.business_owner? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
