Rails.application.routes.draw do
  # Tracking routes
  get '/track/opens/:email_event_id', to: 'tracking#open', as: :track_open
  get '/track/clicks/:email_event_id', to: 'tracking#click', as: :track_click
  post '/emails', to: 'emails#create'
  resources :email_templates
  resources :contacts
  resources :contact_lists do
    member do
      post :add_contact
      delete :remove_contact
    end
  end
  resources :campaigns do
    member do
      post :send
    end
  end

  namespace :api do
    namespace :v1 do
      post '/login', to: 'authentication#login'
      post '/register', to: 'authentication#register'
      resources :contacts do
        collection do
          post :import
          get :export
        end
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
