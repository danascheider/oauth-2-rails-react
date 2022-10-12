# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class AuthorizationsController < ApplicationController
  UNKNOWN_CLIENT = 'Unknown client'
  INVALID_REDIRECT_URI = 'Invalid redirect URI'
  INVALID_SCOPE = 'invalid_scope'

  def authorize
    client = Client.find_by(client_id: query_params[:client_id])

    if client.nil?
      Rails.logger.error "Unknown client #{query_params[:client_id]}"

      render 'error', locals: { error: UNKNOWN_CLIENT }
    elsif client.redirect_uris.exclude?(query_params[:redirect_uri])
      Rails.logger.error "Mismatched redirect URIs - expected #{client.redirect_uris.join(', ')}, got #{query_params[:redirect_uri]}"

      render 'error', locals: { error: INVALID_REDIRECT_URI }
    else
      request_scope = query_params[:scope]&.split(' ') || []

      if (request_scope - client.scope).present?
        url_parsed = URI.parse(query_params[:redirect_uri])
        query = CGI.parse(url_parsed.query || '')
        query[:error] = INVALID_SCOPE

        url_parsed.query = URI.encode_www_form(query)

        redirect_to url_parsed.to_s, status: :found
        return
      end

      req = Request.create!(
        client:,
        reqid: SecureRandom.hex(8),
        query: URI.encode_www_form(request.query_parameters),
        scope: request_scope,
        redirect_uri: query_params[:redirect_uri]
      )

      render 'authorize', locals: { client:, request: req, request_scope: }, status: :ok
    end
  end

  def approve
  end

  def token
  end
end
