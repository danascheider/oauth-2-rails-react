# frozen_string_literal: true

Rails.application.routes.draw do
  root 'base#index'

  get 'authorize', to: 'authorizations#authorize'
  post 'approve', to: 'authorizations#approve'
end
