Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "dashboard#index"

  resources :users, only: [:index]

  resources :leagues do
    resources :tournaments, only: [:new, :create]
    member do
      post :join
      delete :leave
    end
  end
  resources :tournaments do
    member do
      post :open_registration
    end
  end
end
