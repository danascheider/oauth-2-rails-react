# frozen_string_literal: true

Rails.application.routes.draw do
  root 'base#index'

  resources :resources, only: :index
end
