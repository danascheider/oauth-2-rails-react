# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'cgi'

class OauthController < ApplicationController
  def authorize
    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      client_id: configatron.oauth.client.client_id,
      scope: 'foo',
      redirect_uri: configatron.oauth.client.redirect_uris[0]
    }

    uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    query = CGI.parse(uri.query || '').merge(data)
    uri.query = URI.encode_www_form(data)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    redirect_to uri.to_s, status: :found
  end

  def callback
    # TODO: Front end should send query to back end with its params and status
    corresponding_request = AuthorizationRequest.find_by(state: params[:state])

    if corresponding_request.nil?
      Rails.logger.error "No corresponding request found for state '#{params[:state]}'"
      render json: { error: 'State value did not match' }, status: :bad_request
      return
    end

    query_string = {
      grant_type: 'authorization_code',
      code: params[:code],
      redirect_uri: configatron.oauth.client.redirect_uris[0]
    }

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Bearer #{client_bearer_token}"
    }

    Rails.logger.info "Requesting access for code '#{params[:code]}'"
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

  def client_bearer_token
    client_id = CGI.escape(configatron.oauth.client.client_id)
    client_secret = CGI.escape(configatron.oauth.client.client_secret)

    Base64.encode64("#{client_id}:#{client_secret}")
  end
end
