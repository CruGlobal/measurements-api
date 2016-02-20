require 'sidekiq/web'
Rails.application.routes.draw do
  get 'monitors/lb'
  api_version(module: 'V5', path: { value: 'v5' }) do
    resources :token, only: [:index, :destroy]
    resources :assignments, only: [:index, :show, :create, :update]
    resources :churches, only: [:index, :create, :update]
    resources :measurement_types, only: [:index, :show, :create, :update]
    resources :measurements, only: [:index, :show, :create]
    resources :ministries, only: [:index, :show, :create, :update]
    resources :target_cities, only: [:index, :show, :create, :update]
    resources :training_completion, only: [:create, :update, :destroy]
    resources :trainings, only: [:index, :create, :update, :destroy]
    resources :user_preferences, only: [:index, :create]
  end

  mount Sidekiq::Web => '/sidekiq'
end
