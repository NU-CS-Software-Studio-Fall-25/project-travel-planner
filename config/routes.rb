Rails.application.routes.draw do
  # Set the root route to home page (serves both web and API)
  root "home#index"
  
  get "home/index"
  
  # Authentication routes
  get "/signup", to: "users#new"
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  
  # API routes
  namespace :api do
    namespace :v1 do
      resources :users
      resources :destinations
      resources :travel_plans
      resources :travel_recommendations, only: [:index, :show, :create]
    end
  end
  
  # Traditional web routes (for backward compatibility)
  resources :travel_recommendations, only: [:index, :show, :new, :create]
  resources :travel_plans
  resources :destinations
  resources :users
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  
  # Catch all unmatched routes and show custom 404 page (must be last)
  match '*path', to: 'errors#not_found', via: :all
end
