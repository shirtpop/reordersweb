Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # Updated to use new storefront instead of old catalogs list
  root "storefront#index"

  # Storefront routes (new customer-facing e-commerce experience)
  get "/shop" => "storefront#index", as: :storefront
  resources :products, only: [ :show ]  # Product detail pages for ordering
  resource :cart, only: [ :show ], controller: "cart"  # Shopping cart
  resources :cart_items, only: [ :create, :update, :destroy ]  # Add/update/remove from cart
  resource :checkout, only: [ :show, :create ], controller: "order_checkout"  # Order checkout flow (different from inventory checkout)

  devise_for :users, controllers: {
    sessions: "users/sessions",
    passwords: "users/passwords"
  }

  as :user do
    get "users/edit" => "users/registrations#edit",   as: :edit_user_registration
    put "users"      => "users/registrations#update", as: :user_registration
  end

  namespace :admin do
    root to: "dashboard#index", as: :root
    get "dashboard/chart_data", to: "dashboard#chart_data"
    resources :clients do
      resources :products, only: [ :index, :show ], controller: "client_products"
      resource :product_assignments, only: [ :show ], controller: "client_product_assignments"
      resources :catalogs, only: [ :create, :update, :destroy ], controller: "client_catalogs" do
        resource :products, only: [ :update ], controller: "catalog_products", as: :catalog_products
      end
      get :new_wizard, on: :collection
    end
    resources :users
    resources :orders, only: [ :index, :show ] do
      member do
        post :mark_as_processing
      end
    end
    resources :products do
      member do
        post :duplicate
      end
    end
    resources :catalogs
  end

  resources :inventories, only: [ :index ] do
    collection do
      get :adjustments
      get :search_products
      post :save_adjustments
      resources :checkouts, only: [ :index, :show, :new, :create ], as: :inventory_checkouts
      resources :products do
        collection do
          get :barcodes
          get :admin_products
        end

        member do
          post :upload_images
          delete "delete_image/:drive_file_id", to: "products#delete_image", as: :delete_image
        end
      end
      resources :product_variants, only: [ :index, :show ], param: :sku
    end

    member do
      resources :inventory_movements, only: [ :index ]
    end
  end
  resources :orders, only: [ :index, :show, :create ] do
    member do
      post :received
      post :duplicate
    end
  end
  resources :catalogs, only: [ :index, :show ]
  resources :checkouts, only: [ :index, :show, :new, :create ]

  post "drive_files/:attachable_type/:attachable_id", to: "admin/drive_files#create", as: :drive_files
  delete "drive_files/:attachable_type/:attachable_id/:id", to: "admin/drive_files#destroy", as: :drive_file
end
