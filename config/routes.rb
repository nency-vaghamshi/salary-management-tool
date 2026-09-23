Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # HR sign-in is a custom Stimulus-driven form posting to the JSON API below,
  # so Devise's own routes/controllers are unused here; this just registers
  # the User mapping Devise needs internally.
  devise_for :users, skip: :all

  get "login", to: "sessions#new"
  get "register", to: "registrations#new"
  get "dashboard", to: "dashboard#index"
  resources :employees do
    resource :salary_revision, only: %i[new create], controller: "salary_revisions"
  end
  resources :salary_components, only: %i[index new create edit update] do
    member do
      patch :toggle_active
    end
  end
  root "dashboard#index"

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
