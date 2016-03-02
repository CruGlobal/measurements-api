require 'sidekiq/web'
Rails.application.routes.draw do
  get 'monitors/lb'
  api_version(module: 'V5', path: { value: 'v5' }) do
    resources :token, only: [:index, :destroy]
    resources :assignments, only: [:index, :show, :create, :update]
    resources :churches, only: [:index, :create, :update]
    resources :measurement_types, only: [:index, :create, :update]
    get '/measurement_type/:id', to: 'measurement_types#show'
    resources :sys_measurement_types, only: [:index, :create, :update]
    get '/sys_measurement_type/:id', to: 'sys_measurement_types#show'
    resources :measurements, only: [:index, :show, :create]
    resources :ministries, only: [:index, :show, :create, :update]
    resources :target_cities, only: [:index, :show, :create, :update]
    resources :training_completions, only: [:create, :update, :destroy], path: 'training_completion'
    resources :trainings, only: [:index, :create, :update, :destroy], path: 'training'
    resources :user_preferences, only: [:index, :create]
  end

  mount Sidekiq::Web => '/sidekiq'
end
