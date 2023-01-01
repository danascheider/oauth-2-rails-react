# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def oauth_client_credentials
    client_id = CGI.escape(configatron.oauth.client.client_id)
    client_secret = CGI.escape(configatron.oauth.client.client_secret)

    Base64.encode64("#{client_id}:#{client_secret}")
  end

  def query_params
    request.query_parameters
  end

  def verify_token
    redirect_to authorize_path if AccessToken.count == 0
  end

  def access_token
    @access_token ||= AccessToken.last
  end

  def refresh_access_token(refresh_token, &block)
    form_data = {
      grant_type: 'refresh_token',
      refresh_token:
    }

    headers = {
      'Authorization' => "Basic #{oauth_client_credentials}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    Rails.logger.debug "Refreshing token with refresh token '#{refresh_token}'"

    token_response = Faraday.post(configatron.oauth.auth_server.token_endpoint, URI.encode_www_form(form_data), headers)

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)

      token = body[:access_token]
      Rails.logger.debug "Got access token: '#{token}'"

      scope = body[:scope]
      Rails.logger.debug "Got scope: '#{scope}'"

      if body[:refresh_token].present?
        Rails.logger.debug "Got refresh token: '#{body[:refresh_token]}'"
        refresh_token = body[:refresh_token]
      end

      access_token&.destroy!
      @access_token = AccessToken.create!(access_token: token, refresh_token:, token_type: 'Bearer', scope: scope&.split(' ') || [])

      return true
    else
      Rails.logger.info 'Invalid refresh token, user must reauthorize'

      render json: { error: 'Unable to refresh token. User must reauthorize.' }, status: :unauthorized
    end
  end
end
