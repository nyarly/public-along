require 'sidekiq/web'

Rails.application.routes.draw do
  resources :approvals, except: :destroy
  resources :access_levels
  resources :applications
  resources :departments
  resource :emails, only: :create
  namespace :employees, as: :employee do
    resources :new_hires, only: :index
    resources :inactives, only: :index
    resources :offboards, only: :index
  end
  resources :employees, only: [:index, :show] do
    get :autocomplete_name, on: :collection
    get :autocomplete_email, on: :collection
    get :direct_reports, on: :member
  end
  resources :emp_transactions, except: [:edit, :update, :destroy]
  resources :locations do
    resources :addresses, only: [:new, :create, :edit, :update]
  end
  resources :machine_bundles
  resources :parent_orgs
  resources :security_profiles
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  resources :worker_types

  get '/app_access_levels' => "security_profiles#app_access_levels", as: 'app_access_levels'
  get '/sp_access_level' => "security_profiles#sp_access_level", as: 'sp_access_level'

  devise_scope :user do
    root to: "employees#index"
    get  '/login' => "users/sessions#new", :as => :login
    get  '/logout' => "users/sessions#destroy", :as => :logout
  end

  authenticate :user, lambda { |u| u.role_names.include?("Admin") } do
    Sidekiq::Web.session_secret = Rails.application.secrets[:secret_key_base]
    mount Sidekiq::Web => '/sidekiq'
  end
end
