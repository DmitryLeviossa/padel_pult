Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "leagues#index"

  resources :users, only: [:index]

  resources :leagues do
    resources :tournaments, only: [:new, :create]
  end
  resources :tournaments
end
