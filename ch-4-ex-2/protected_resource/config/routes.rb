# frozen_string_literal: true

Rails.application.routes.draw do
  root 'base#index'

  resources :words, only: %i[index create] do
    delete :destroy, on: :collection
  end
end
