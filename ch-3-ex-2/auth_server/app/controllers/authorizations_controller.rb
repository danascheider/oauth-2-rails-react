# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class AuthorizationsController < ApplicationController
  UNKNOWN_CLIENT = 'Unknown client'
  INVALID_REDIRECT_URI = 'Invalid redirect URI'
  INVALID_SCOPE = 'invalid_scope'
  UNSUPPORTED_RESPONSE_TYPE = 'unsupported response_type'
  ACCESS_DENIED = 'access_denied'

  def authorize
    if client.nil?
      Rails.logger.error "Unknown client #{query_params[:client_id]}"

      render 'error', locals: { error: UNKNOWN_CLIENT }
    elsif client.redirect_uris.exclude?(query_params[:redirect_uri])
      Rails.logger.error "Mismatched redirect URIs - expected #{client.redirect_uris.join(', ')}, got #{query_params[:redirect_uri]}"

      render 'error', locals: { error: INVALID_REDIRECT_URI }
    else
      req_scope = query_params[:scope]&.split(' ') || []

      disallowed_scopes = req_scope - client.scope

      if disallowed_scopes.present?
        Rails.logger.error "Invalid scope(s) requested: #{disallowed_scopes.join(', ')}"

        render 'error', locals: { error: "Invalid scope(s) requested: #{disallowed_scopes.join(', ')}" }
        return
      end

      @req = Request.create!(
        client:,
        reqid: SecureRandom.hex(8),
        query: URI.encode_www_form(request.query_parameters),
        scope: request_scope,
        redirect_uri: query_params[:redirect_uri]
      )

      render 'authorize', locals: { client:, req_scope: }, status: :ok
    end
  end

  def approve
    if req.nil?
      Rails.logger.error "Could not find request matching authorization request (reqid #{params[:reqid]})"
      render json: { error: 'No matching authorization request' }, status: :forbidden
      return
    end

    if body_params[:approve]
      query_string = redirect_query_string

      if req.query_hash['response_type'] == 'code'
        destroy_request_model_and_redirect(code_response_uri)
      else
        Rails.logger.error "Invalid response type #{req.query_hash['response_type']}"

        destroy_request_model_and_redirect(unsupported_response_type_uri(query_string))
      end
    else
      Rails.logger.error "Access denied for client #{req.client_id}"

      destroy_request_model_and_redirect(access_denied_uri(query_string))
    end
  end

  def token
  end

  private

  def req
    @req ||= Request.find_by(reqid: body_params[:reqid])
  end

  def client
    @client ||= req.present? ? req.client : Client.find_by(client_id: query_params[:client_id])
  end

  def request_scope
    @request_scope ||= body_params
                        .keys
                        .filter_map {|key| key.to_s.gsub('scope_', '') if key.to_s.start_with?('scope_') }
  end

  def redirect_uri
    @redirect_uri ||= req.present? ? URI.parse(req.redirect_uri) : URI.parse(query_params[:redirect_uri])
  end

  def redirect_query_string
    CGI.parse(redirect_uri.query || '')
  end

  def build_redirect_uri(error, query_string = {})
    query_string['error'] = error
    redirect_uri.query = URI.encode_www_form(query_string)
    redirect_uri
  end

  def invalid_scope_uri(existing_query = {})
    build_redirect_uri(INVALID_SCOPE, existing_query).to_s
  end

  def unsupported_response_type_uri(existing_query = {})
    build_redirect_uri(UNSUPPORTED_RESPONSE_TYPE, existing_query).to_s
  end

  def access_denied_uri(existing_query = {})
    build_redirect_uri(ACCESS_DENIED, existing_query).to_s
  end

  def destroy_request_model_and_redirect(uri)
    Rails.logger.debug "Destroying request reqid #{req.reqid}"
    req.destroy!

    redirect_to uri, status: :found
  end

  def code_response_uri
    query_string = redirect_query_string

    # This code is commented out because it is present in the book's examples but
    # doesn't seem to actually do anything - the approval form doesn't include a param
    # called 'user' in this request so this will always be nil (undefined in the original
    # JS implementation).
    # user = params[:user]

    disallowed_scopes = request_scope - client.scope

    if disallowed_scopes.present?
      Rails.logger.error "Invalid scope(s) requested: #{disallowed_scopes.join(', ')}"

      return invalid_scope_uri(query_string)
    end

    code = SecureRandom.hex(8)

    AuthorizationCode.create!(code:, authorization_endpoint_request: req.attributes, scope: request_scope)
    Rails.logger.debug "Authorization code created with code #{code}"

    query_string['code'] = code
    query_string['state'] = req.query_hash['state']
    redirect_uri.query = URI.encode_www_form(query_string)

    redirect_uri.to_s
  end
end
