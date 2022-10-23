# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class OauthController < ApplicationController
  def authorize
    redirect_uri = configatron.oauth.client.redirect_uris[query_params[:redirect_page]&.to_sym] || configatron.oauth.client.redirect_uris[:callback]

    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      client_id: configatron.oauth.client.client_id,
      scope: configatron.oauth.client.scope,
      redirect_uri:
    }

    uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    query = CGI.parse(uri.query || '').merge(data)
    uri.query = URI.encode_www_form(query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    redirect_to uri.to_s, status: :found
  end

  def callback
    if query_params[:error]
      render json: { error: }, status: :forbidden
      return
    end

    auth_request = AuthorizationRequest.find_by(state: query_params[:state])

    if auth_request.nil?
      Rails.logger.error "State '#{query_params[:state]}' DOES NOT MATCH any existing authorization request."
      render json: { error: 'State value did not match' }, status: :bad_request
      return
    end

    form_data = {
      grant_type: 'authorization_code',
      code: query_params[:code],
      redirect_uri: auth_request.redirect_uri
    }

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{client_credentials}"
    }

    Rails.logger.info "Requesting access for code '#{query_params[:code]}'"
    token_response = Faraday.post(
                                   configatron.oauth.auth_server.token_endpoint,
                                   URI.encode_www_form(form_data),
                                   headers
                                 )

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)

      access_token = body[:access_token]

      refresh_token = body[:refresh_token]
      Rails.logger.info "Got refresh token: '#{refresh_token}'" if refresh_token.present?

      scope = body[:scope]
      Rails.logger.info "Got scope: '#{scope}'"

      AccessToken.create!(access_token:, refresh_token:, token_type: body[:token_type], scope: scope.split(' '))

      render json: { access_token:, refresh_token:, scope: }, status: :ok
    else
      render json: { error: "Unable to fetch token, server response: #{token_response.status}" }, status: token_response.status
    end
  end
end
