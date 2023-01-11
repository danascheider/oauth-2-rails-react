# frozen_string_literal: true

Rails.application.routes.draw do
  get 'authorize', to: 'oauth#authorize'
end
