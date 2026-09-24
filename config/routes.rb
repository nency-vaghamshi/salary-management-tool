Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # HR sign-in is a custom Stimulus-driven form posting to the JSON API below,
  # so only Devise's password-reset routes are exposed; sessions and
  # registrations stay on the custom JWT flow.
  devise_for :users, only: :passwords, controllers: { passwords: "users/passwords" }

  get "login", to: "sessions#new"
  get "register", to: "registrations#new"
  get "dashboard", to: "dashboard#index"
  resources :employees
  resources :salary_records, only: %i[new create show]
  resources :payroll_runs, only: %i[index new create show]
  resources :payslips, only: :show
  root "dashboard#index"

  namespace :api do
    namespace :v1 do
      post "auth/signup", to: "auth#signup"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      resources :employees, except: %i[new edit] do
        member do
          get :salary_history
        end
      end

      resources :salary_records, only: %i[create show]
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
