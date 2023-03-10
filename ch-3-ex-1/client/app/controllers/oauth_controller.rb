# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'cgi'

class OauthController < ApplicationController
  def authorize
    redirect_uri = configatron.oauth.client.redirect_uris[query_params[:redirect_page]&.to_sym] || configatron.oauth.client.redirect_uris[:callback]

    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      client_id: configatron.oauth.client.client_id,
      scope: 'foo',
      redirect_uri:
    }

    uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    query = CGI.parse(uri.query || '').merge(data)
    uri.query = URI.encode_www_form(query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    redirect_to uri.to_s, status: :found
  end

  def callback
    corresponding_request = AuthorizationRequest.find_by(state: query_params[:state])

    if corresponding_request.nil?
      Rails.logger.error "No corresponding request found for state '#{query_params[:state]}'"
      render json: { error: 'State value did not match' }, status: :bad_request
      return
    end

    query_string = {
      grant_type: 'authorization_code',
      code: query_params[:code],
      redirect_uri: corresponding_request.redirect_uri
    }

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{client_credentials}"
    }

    Rails.logger.info "Requesting access for code '#{query_params[:code]}'"
    token_response = Faraday.post(
                                   configatron.oauth.auth_server.token_endpoint,
                                   URI.encode_www_form(query_string),
                                   headers
                                 )

    if token_response.success?
      body = JSON.parse(token_response.body, symbolize_names: true)
      access_token = body[:access_token]
      scope = body[:scope]

      AccessToken.create!(access_token:, token_type: body[:token_type], scope: scope&.split(' '))

      Rails.logger.info "Got access token: '#{access_token}'"

      render json: { access_token:, scope: }, status: :ok
    else
      Rails.logger.error "Unable to fetch access token, server returned status #{token_response.status}"

      render json: { error: "Unable to fetch access token, server response: #{token_response.status}" }, status: token_response.status
    end
  end

  private

  def client_credentials
    client_id = CGI.escape(configatron.oauth.client.client_id)
    client_secret = CGI.escape(configatron.oauth.client.client_secret)

    Base64.encode64("#{client_id}:#{client_secret}")
  end
end
