Rails.application.routes.draw do
  root 'base#index'

  resources :resources, only: %i[index show]
end
