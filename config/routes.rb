Rails.application.routes.draw do
  root 'main#index'
  post '/' => 'main#create'
  resources :orders, only: [:show, :destroy]
  # get 'diplomas' => 'main#diplomas'

end
