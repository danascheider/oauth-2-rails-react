# frozen_string_literal: true

Rails.application.routes.draw do
  get 'token', to: 'tokens#fetch'
end
