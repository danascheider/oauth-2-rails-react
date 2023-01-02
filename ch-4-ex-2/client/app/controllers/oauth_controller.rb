# frozen_string_literal: true

class OauthController < ApplicationController
  def authorize
    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      client_id: configatron.oauth.client.client_id,
      scope: configatron.oauth.client.scope,
      redirect_uri: configatron.oauth.client.default_redirect_uri,
    }

    auth_url = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    uri_query = CGI.parse(auth_url.query || '').merge(data)
    uri_query['scope'] = configatron.oauth.client.scope
    auth_url.query = URI.encode_www_form(uri_query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    Rails.logger.debug "Redirecting to #{authorize_url}"
    redirect_to auth_url.to_s, status: :found
  end

  def callback
    if query_params[:error].present?
      render json: { error: query_params[:error] }, status: :forbidden
      return
    end

    if authorization_request.nil?
      Rails.logger.error "State value #{query_params[:state]} did not match an existing authorization request"
      render json: { error: 'State value did not match' }, status: :forbidden
      return
    end

    form_data = {
      grant_type: 'authorization_code',
      code: query_params[:code],
      user: query_params[:user],
      redirect_uri:
    }

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{oauth_client_credentials}"
    }

    Rails.logger.info "Requesting access token for code '#{query_params[:code]}'"

    token_response = Faraday.post(
                       configatron.oauth.auth_server.token_endpoint,
                       URI.encode_www_form(form_data),
                       headers
                     )

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)

      access_token, refresh_token, scope = body[:access_token], body[:refresh_token], body[:scope]

      Rails.logger.info "Got access token: '#{access_token}'"
      Rails.logger.info "Got refresh token: '#{refresh_token}'" if refresh_token.present?
      Rails.logger.info "Got scope: '#{scope}'"

      AccessToken.create!(
        access_token:,
        refresh_token:,
        scope:,
        token_type: 'Bearer'
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
    @authorization_request ||= AuthorizationRequest.find_by(state: query_params[:state])
  end

  def redirect_uri
    configatron.oauth.client.default_redirect_uri
  end
end
