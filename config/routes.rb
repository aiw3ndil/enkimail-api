require 'sidekiq/web'
require 'rack/session/cookie'
Sidekiq::Web.use Rack::Session::Cookie, secret: Rails.application.credentials.secret_key_base, same_site: :lax, max_age: 86400

Rails.application.routes.draw do
  # Tracking routes
  get '/track/opens/:email_event_id', to: 'tracking#open', as: :track_open
  get '/track/clicks/:email_event_id', to: 'tracking#click', as: :track_click
  post '/emails', to: 'emails#create'

  namespace :webhooks do
    post 'mta', to: 'mta#create'
  end
  
  
  namespace :api do
    namespace :v1 do
      post '/login', to: 'authentication#login'
      post '/register', to: 'authentication#register'
      resources :email_templates
      resources :contacts do
        collection do
          post :import
          get :export
        end
      end
      resources :contact_lists do
        member do
          post :add_contact
          delete :remove_contact
        end
      end
      resources :campaigns do
        member do
          post :send_campaign
        end
      end
      post '/transactional_emails', to: 'transactional_emails#create'
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get '/dashboard', to: 'dashboard#index'

  # Defines the root path route ("/")
  # root "posts#index"

  mount Sidekiq::Web => '/sidekiq'
end
