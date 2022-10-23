# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class AuthorizationsController < ApplicationController
  skip_forgery_protection except: :authorize

  INVALID_SCOPE = 'invalid_scope'

  def authorize
    @client_id = query_params[:client_id]

    if client.nil?
      Rails.logger.error "Unknown client #{query_params[:client_id]}"
      render 'error', locals: { error: 'Unknown client' }
      return
    elsif client.redirect_uris.exclude?(redirect_uri.to_s)
      Rails.logger.error "Mismatched redirect URI: expected '#{client.redirect_uri}', got '#{redirect_uri}'"
      render 'error', locals: { error: 'Invalid redirect URI' }
      return
    else
      request_scope = query_params[:scope]&.split(' ') || []
      disallowed_scopes = request_scope - client.scope

      if disallowed_scopes.present?
        Rails.logger.error "Invalid scope(s) requested: #{disallowed_scopes.join(', ')}"

        query = CGI.parse(redirect_uri.query || '')
        query['error'] = INVALID_SCOPE
        redirect_uri.query = URI.encode_www_form(query)

        redirect_to redirect_uri, status: :found
        return
      end

      @req = Request.create!(
        client:,
        reqid: SecureRandom.hex(8),
        query: URI.encode_www_form(query_params),
        scope: request_scope,
        redirect_uri:
      )

      render 'authorize'
    end
  end

  private

  attr_reader :client_id

  def redirect_uri
    @redirect_uri ||= req.present? ? URI.parse(req.redirect_uri) : URI.parse(query_params[:redirect_uri])
  end

  def client
    @client ||= req.present? ? req.client : Client.find_by(client_id:)
  end

  def req
    @req ||= Request.find_by(req_id: body_params[:reqid])
  end
end