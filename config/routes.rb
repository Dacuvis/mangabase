Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      resources :mangas do
        member do
          get :recommendations
        end
      end
      resources :genres
      resources :users
      resources :manga_genres
      resources :reading_lists
      resources :best_mangas
      resources :underrated_mangas
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
