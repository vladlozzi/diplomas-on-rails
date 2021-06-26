Rails.application.routes.draw do
  root 'main#index'
  post '/' => 'main#create'
  delete '/' => 'main#delete_orders'
  resources :orders, only: [:show, :destroy]
  get '/diplomas' => 'main#get_diplomas'
  # get '/send_diplomas_zip' => 'main#send_diplomas_zip'
end
