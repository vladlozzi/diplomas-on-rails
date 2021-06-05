Rails.application.routes.draw do
  root 'main#index'
  post '/' => 'main#create'
  # delete '/' => 'main#delete'
  # get 'create' => 'create_diplomas'
end
