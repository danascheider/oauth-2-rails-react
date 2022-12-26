# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'cgi'

class OauthController < ApplicationController
  def authorize
    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      scope: configatron.oauth.client.scope,
      client_id: configatron.oauth.client.client_id,
      redirect_uri: configatron.oauth.client.redirect_uris[0],
    }

    uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    uri_query = CGI.parse(uri.query || '').merge(data)
    uri_query['scope'] = configatron.oauth.client.scope
    uri.query = URI.encode_www_form(uri_query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    redirect_to uri.to_s, status: :found
  end

  def callback
    if query_params[:error].present?
      render json: { error: query_params[:error] }, status: :forbidden
      return
    end

    if authorization_request.nil?
      console.error "State value #{query_params[:state]} did not match an existing authorization request"
      render json: { error: 'State value did not match' }, status: :forbidden
      return
    end

    form_data = {
      code: query_params[:code],
      user: query_params[:user],
      grant_type: 'authorization_code',
      redirect_uri: configatron.oauth.client.redirect_uris.first
    }

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{oauth_client_credentials}"
    }

    token_response = Faraday.post(
                                    configatron.oauth.auth_server.token_endpoint,
                                    URI.encode_www_form(form_data),
                                    headers
                                  )

    Rails.logger.info "Requested access token for code '#{query_params[:code]}'"

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
end
