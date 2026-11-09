Rails.application.routes.draw do
  devise_for :admin_users, path: "admin", controllers: { sessions: "admin/sessions" }

  namespace :admin do
    root "dashboards#show"
    resources :users, except: :show
    resources :work_locations, only: %i[ index new create edit update ]
    resources :reports, only: %i[ index show new create ]
    resource :analytics, only: :show
  end

  # LIFF app opened from LINE: staff report their own booth's results.
  namespace :liff do
    root "entries#show"
    resource :session, only: %i[ create destroy ]
    resources :reports, only: %i[ new create show ]
  end

  namespace :api do
    namespace :linebot do
      post "callback", to: "callbacks#create"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
