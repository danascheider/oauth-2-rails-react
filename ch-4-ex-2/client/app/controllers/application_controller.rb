# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def oauth_client_credentials
    client_id = CGI.escape(configatron.oauth.client.client_id)
    client_secret = CGI.escape(configatron.oauth.client.client_secret)

    Base64.encode64("#{client_id}:#{client_secret}")
  end

  def query_params
    request.query_parameters
  end
end
