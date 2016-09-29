Rails.application.routes.draw do
  resources :notifications
  resources :pois
  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  mount Sidekiq::Web => '/sidekiq'

  resources :crime_type_descriptions do
    get 'remark', on: :collection
  end

  resources :scheduled_jobs
  devise_for :users, :path => '',
  :path_names => {
  	:sign_in => 'login',
  	:sign_out => 'logout'
  }
  resources :users
  resources :offenses
  resources :cities
  resources :crime_types do
    get 'list_descriptions', on: :member
  end
  resources :dashboard
  resources :spike_alert
  resources :map
  resources :cities_crime_type_weights do
    get 'update_table', on: :collection
  end
  resources :workers

  resources :crime_data do
    get 'reports', on: :collection
    get 'crimes_by_day', on: :collection
    get 'top_crimes', on: :collection
    get 'crimes_by_day', on: :collection
    get 'crimes_by_hour', on: :collection
    get 'crimes_by_ward', on: :collection
    get 'crimes_by_block', on: :collection
    get 'top_unsafe_addresses', on: :collection
    get 'test',on: :collection
  end


# API
  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      resources :reports do
        get 'wards_report', on: :collection
        get 'crime_type_report', on: :collection
        get 'narcotics_report', on: :collection
      end
      resources :map do
        get 'tips', on: :collection
        get 'visualize_current', on: :collection
      end
    end
  end

  root to: 'crime_type_descriptions#index'

end
