Rails.application.routes.draw do
  root 'base#index'

  post '/resources', to: 'resources#index'
end
