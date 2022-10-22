# frozen_string_literal: true

require 'uri'

class ResourcesController < ApplicationController
  def fetch
    access_token = AccessToken.last
    Rails.logger.info "Making request with access token '#{access_token.access_token}'"

    if access_token.nil?
      render json: { error: 'Please authenticate before fetching protected resource.' }, status: :forbidden
      return
    end

    headers = {
      'Authorization' => "Bearer #{access_token.access_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    response = Faraday.post(configatron.oauth.resource.endpoint, nil, headers)

    if response.success?
      resource = JSON.parse(response.body)

      render json: { resource: }, status: :ok
    else
      refresh_token = access_token.refresh_token
      access_token.destroy!

      if refresh_token.present?
        refresh_access_token(refresh_token)
      else
        render json: { error: "Server returned status #{response.status}" }, status: response.status
      end
    end
  end

  private

  def refresh_access_token(refresh_token)
    form_data = {
      grant_type: 'refresh_token',
      refresh_token:
    }

    headers = {
      'Authorization' => "Basic #{client_credentials}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    Rails.logger.debug "Refreshing token with refresh token '#{refresh_token}'"

    token_response = Faraday.post(configatron.oauth.auth_server.token_endpoint, URI.encode_www_form(form_data), headers)

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)

      access_token = body[:access_token]
      Rails.logger.debug "Got access token: '#{access_token}'"

      scope = body[:scope]
      Rails.logger.debug "Got scope: '#{scope}'"

      if body[:refresh_token].present?
        Rails.logger.debug "Got refresh token: '#{body[:refresh_token]}'"
        refresh_token = body[:refresh_token]
      end

      AccessToken.create!(access_token:, refresh_token:, token_type: 'Bearer', scope: scope.split(' '))

      redirect_to fetch_resource_path, status: :found
    else
      Rails.logger.info 'Invalid refresh token, user must reauthorize'

      render json: { error: 'Unable to refresh token. User must reauthorize.' }, status: :unauthorized
    end
  end
end
