# frozen_string_literal: true

class OauthController < ApplicationController
  def authorize
    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      client_id: configatron.oauth.client.client_id,
      scope: configatron.oauth.client.scope,
      redirect_uri: configatron.oauth.client.default_redirect_uri
    }

    auth_url = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    uri_query = CGI.parse(auth_url.query || '').merge(data)
    auth_url.query = URI.encode_www_form(uri_query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    Rails.logger.info "Redirecting to #{auth_url}"
    redirect_to auth_url.to_s, status: :found, allow_other_host: true
  end

  def callback
    if query_params[:error].present?
      render json: { error: query_params[:error] }, status: :forbidden
      return
    end

    if authorization_request.nil?
      Rails.logger.error "State value '#{query_params[:state]}' did not match an existing authorization request"
      render json: { error: 'State value did not match' }, status: :forbidden
      return
    end

    Rails.logger.info "State value '#{query_params[:state]}' matches"

    form_data = URI.encode_www_form({
                                      grant_type: 'authorization_code',
                                      code: query_params[:code],
                                      redirect_uri: default_redirect_uri
                                    })

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{oauth_client_credentials}"
    }

    Rails.logger.info "Requesting access token for code '#{query_params[:code]}'"

    token_response = Faraday.post(configatron.oauth.auth_server.token_endpoint, form_data, headers)

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)

      access_token, refresh_token, scope, user, token_type = body.values_at(:access_token, :refresh_token, :scope, :user, :token_type)

      Rails.logger.info "Got access token: #{access_token}"
      Rails.logger.info "Got refresh token: #{refresh_token}" if refresh_token.present?
      Rails.logger.info "Got scope: #{scope}"

      AccessToken.create!(
        access_token:,
        refresh_token:,
        user:,
        scope:,
        token_type:
      )

      render json: { access_token:, refresh_token:, scope: }, status: :ok
    else
      Rails.logger.error JSON.parse(token_response.body, symbolize_names: true)[:error]
      error = "Unable to fetch access token, error (#{token_response.status})"
      render json: { error: }, status: token_response.status
    end
  end

  private

  def authorization_request
    AuthorizationRequest.find_by(state: query_params[:state])
  end

  def default_redirect_uri
    configatron.oauth.client.default_redirect_uri
  end
end
