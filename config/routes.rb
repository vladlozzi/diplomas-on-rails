Rails.application.routes.draw do
  root 'main#index'
  post '/' => 'main#create'
  delete '/' => 'main#delete_orders'
  resources :orders, only: [:show, :destroy]
  # get 'diplomas' => 'main#diplomas'

end
