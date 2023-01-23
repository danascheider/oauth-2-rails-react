# frozen_string_literal: true

class ProduceController < ApplicationController
  def fetch
    access_token = AccessToken.last

    if access_token.nil?
      Rails.logger.error 'No access tokens in database'
      render json: { error: 'Missing access token' }, status: :unauthorized
      return
    end

    headers = {
      'Authorization' => "Bearer #{access_token.access_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    Rails.logger.info "Requesting produce from API with access token '#{access_token.access_token}'"
    resp = Faraday.get(configatron.oauth.protected_resource.uri, nil, headers)

    if resp.status == 401
      Rails.logger.error '401 response from protected resource server'
      render json: { error: '401 response from protected resource server' }, status: :unauthorized
      return
    end

    produce = resp.body.present? ? JSON.parse(resp.body, symbolize_names: true) : {}

    if resp.success?
      render json: { scope: access_token.scope.join(' '), produce: }, status: :ok
    else
      if produce.present? && produce.key?(:error)
        Rails.logger.error "Error response #{resp.status} received from server: #{produce[:error]}"
        render json: { error: produce[:error] }, status: :ok
      else
        error = "Error response #{resp.status} received from server"
        Rails.logger.error error
        render json: { error: }, status: :ok
      end
    end
  end
end
