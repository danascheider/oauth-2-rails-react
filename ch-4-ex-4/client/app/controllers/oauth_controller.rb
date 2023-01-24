# frozen_string_literal: true

class OauthController < ApplicationController
  def authorize
    data = {
      response_type: 'code',
      scope: configatron.oauth.client.scope,
      client_id: configatron.oauth.client.client_id,
      redirect_uri: configatron.oauth.client.default_redirect_uri,
      state: SecureRandom.hex(8)
    }

    auth_uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    uri_query = CGI.parse(auth_uri.query || '').merge(data)
    auth_uri.query = URI.encode_www_form(uri_query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    Rails.logger.info "Redirecting to #{auth_uri}"
    redirect_to auth_uri.to_s, status: :found, allow_other_host: true
  end

  def callback
  end
end
