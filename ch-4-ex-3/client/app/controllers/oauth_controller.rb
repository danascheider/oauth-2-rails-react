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
end
