Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "dashboard#index"

  resources :users, only: [:index, :show]

  resources :leagues do
    resources :tournaments, only: [:new, :create]
    resources :league_users, only: [:new, :create], module: :leagues
    resources :league_invitations, only: [:create], module: :leagues
    member do
      post :join
      delete :leave
    end
  end

  resources :league_invitations, only: [:update]

  get  "invitations/:token", to: "invitations#show",   as: :invitation
  patch "invitations/:token", to: "invitations#update"
  resources :notifications, only: [] do
    member do
      get :visit
    end
    collection do
      patch :mark_all_read
    end
  end

  resources :tournaments do
    resources :pairs, only: [ :create, :destroy ]
    member do
      post :open_registration
      get :fill_results
      patch :complete
    end
  end
end
