require 'sidekiq/web'

Rails.application.routes.draw do
  resources :access_levels
  resources :applications
  resources :departments
  resource :emails, only: :create
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

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
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
