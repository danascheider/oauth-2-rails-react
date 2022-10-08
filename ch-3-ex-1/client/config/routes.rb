# frozen_string_literal: true

Rails.application.routes.draw do
  get 'fetch_resource', to: 'resources#fetch'
  get 'authorize', to: 'oauth#authorize'
  get 'callback', to: 'oauth#callback'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
