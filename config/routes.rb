Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "orders#index"
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  namespace :admin do
    root to: 'dashboard#index', as: :root
    resources :clients
    resources :users, only: [:index, :create, :update, :destroy]
    resources :orders
    resources :products
    resources :projects
  end

  resources :orders, only: [:index, :show]
  resources :products, only: [:index]
  get 'cart', to: 'cart#show', as: :cart
end
