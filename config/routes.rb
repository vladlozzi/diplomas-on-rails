Rails.application.routes.draw do
  root 'main#init'
  post '/' => 'main#upload'
  # delete '/' => 'main#delete'
  # get 'create' => 'create_diplomas'
end
