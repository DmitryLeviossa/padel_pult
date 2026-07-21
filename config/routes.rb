require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  devise_for :users, controllers: { registrations: 'users/registrations' }

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "dashboard#index"

  resources :users, only: [:index, :show, :destroy] do
    member do
      post :invite
    end
  end

  resources :leagues do
    resources :tournaments, only: [:new, :create]
    resources :seasons, only: [:new, :create, :show, :edit, :update, :destroy]
    resources :league_users, only: [:new, :create, :edit, :update], module: :leagues
    resources :league_invitations, only: [:create], module: :leagues
    resource :league_telegram_setting, only: [:create, :update], module: :leagues do
      member do
        post :send_test
      end
    end
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

  resources :clubs, only: [:index, :show]

  namespace :admin do
    resources :leagues, only: [:index, :update]
  end

  resources :tournaments do
    resources :brackets, only: [ :new, :create, :destroy ]
    resources :pairs, only: [ :create, :destroy, :update ]
    resources :tournament_participants, only: [ :create, :destroy ]
    resources :matches, only: [ :update, :destroy ] do
      member do
        patch :assign_pairs
        get :result_card
        post :finish
      end
    end
    member do
      post :open_registration
      post :activate
      post :cancel
      get :fill_results
      patch :complete
      get :edit_placements
      patch :update_placements
      get :online
      post :auto_assign_pairs
      patch :assign_group_pairs
      post :seed_bracket
      get :copy
    end
  end
end
