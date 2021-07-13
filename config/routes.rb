Rails.application.routes.draw do
  root "todos#index",format: "json"
  resources :todos, only: [:create, :show, :update, :destroy]
  post "callback", to: "line_bots#callback"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
