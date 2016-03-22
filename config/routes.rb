# frozen_string_literal: true
require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  get 'monitors/lb'

  namespace :gr_sync do
    post "/#{ENV.fetch('GR_NOTIFICATION_URL_SECRET')}/notifications",
         to: 'notifications#create', as: :notifications
  end

  api_version(module: 'V5', path: { value: 'v5' }) do
    resources :token, only: :index
    delete '/token', to: 'token#destroy'
    resources :assignments, only: [:index, :show, :create, :update]
    resources :sys_assignments, only: [:create, :update], controller: 'systems_assignments'
    resources :churches, only: [:index, :create, :update]
    resources :images, only: [:create]
    resources :measurement_types, only: [:index, :show, :create, :update]
    get '/measurement_type/:id', to: 'measurement_types#show'
    resources :sys_measurement_types, only: [:index, :show, :create, :update], controller: 'systems_measurement_types'
    get '/sys_measurement_type/:id', to: 'systems_measurement_types#show'
    resources :measurements, only: [:index, :show, :create]
    resources :sys_measurements, only: [:create], controller: 'systems_measurements'
    resources :ministries, only: [:index, :show, :create, :update]
    resources :sys_ministries, only: [:index, :show, :create, :update], controller: 'systems_ministries'
    resources :stories, only: [:index, :show, :create, :update]
    resources :target_cities, only: [:index, :show, :create, :update]
    resources :training_completions, only: [:create, :update, :destroy], path: 'training_completion'
    resources :trainings, only: [:index, :create, :update, :destroy], path: 'training'
    resources :user_preferences, only: [:index, :create]
    resources :audit, only: :index
  end

  mount Sidekiq::Web, at: "/#{ENV.fetch('SIDEKIQ_URL_SECRET')}/sidekiq"
end
