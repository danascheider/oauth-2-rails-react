# frozen_string_literal: true

Rails.application.routes.draw do
  get 'produce', to: 'produce#fetch'
  get 'authorize', to: 'oauth#authorize'
  get 'callback', to: 'oauth#callback'
end
