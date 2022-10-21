# frozen_string_literal: true

Rails.application.routes.draw do
  get 'fetch_resource', to: 'resources#fetch'
  get 'authorize', to: 'oauth#authorize'
  get 'callback', to: 'oauth#callback'

  get 'token', to: 'tokens#show'
end
