# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class OauthController < ApplicationController
  def authorize
    data = {
      state: SecureRandom.hex(8),
      response_type: 'code',
      client_id: configatron.oauth.client.client_id,
      scope: configatron.oauth.client.scope,
      redirect_uri: configatron.oauth.client.redirect_uris.first
    }

    uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
    query = CGI.parse(uri.query || '').merge(data)
    uri.query = URI.encode_www_form(query)

    AuthorizationRequest.create!(data.except(:client_id, :scope))

    redirect_to uri.to_s, status: :found
  end

  def callback
  end
end
