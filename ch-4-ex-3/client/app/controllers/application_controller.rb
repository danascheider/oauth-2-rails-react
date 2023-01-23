# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def query_params
    request.query_parameters
  end

  def oauth_client_credentials
    client_id = CGI.escape(configatron.oauth.client.client_id)
    client_secret = CGI.escape(configatron.oauth.client.client_secret)

    Base64.encode64("#{client_id}:#{client_secret}")
  end

  def request_token_refresh(access_token, &block)
    headers = {
      'Authorization': "Basic #{oauth_client_credentials}",
      'Content-Type': 'application/x-www-form-urlencoded'
    }

    params = URI.encode_www_form({
      grant_type: 'refresh_token',
      refresh_token: access_token.refresh_token
    })

    token_response = Faraday.post(configatron.oauth.auth_server.token_endpoint, params, headers)

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)

      Rails.logger.info "Refreshed access token: '#{body[:access_token]}'"

      AccessToken.create!(
        access_token: body[:access_token],
        refresh_token: body[:refresh_token],
        scope: body[:scope].split(' '),
        user: body[:user],
        token_type: body[:token_type]
      )

      yield token_response
    elsif token_response.status == 401
      Rails.logger.error "Unable to refresh access token with refresh token '#{access_token.refresh_token}'"
      render json: { error: 'Unauthorized. Failed to refresh access token.' }, status: :unauthorized
    end

    access_token.destroy!
  end
end
