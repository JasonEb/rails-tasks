Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => "/cable"

  namespace :api do
    namespace :v1 do
      resources :users, only: :create
      resources :sessions, only: :create
      get "me", to: "users#me"

      resources :tasks, only: %i[index show create update destroy] do
        resources :comments, only: %i[index create]
      end
      resources :comments, only: :destroy
    end
  end
end
