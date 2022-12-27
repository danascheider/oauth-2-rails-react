# frozen_string_literal: true

Rails.application.routes.draw do
  # Defines the root path route ("/")
  root 'base#index'

  get 'authorize', to: 'authorizations#authorize'
  post 'approve', to: 'authorizations#approve'
  post 'token', to: 'authorizations#token'
end
