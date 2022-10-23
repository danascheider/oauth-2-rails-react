# frozen_string_literal: true

Rails.application.routes.draw do
  get 'authorize', to: 'oauth#authorize'
  get 'callback', to: 'oauth#callback'
  get 'token', to: 'access_tokens#token'
end
