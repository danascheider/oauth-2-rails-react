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
  end
end
