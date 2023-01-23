# frozen_string_literal: true

Rails.application.routes.draw do
  resources :produce, only: :index

  root 'base#index'
end
