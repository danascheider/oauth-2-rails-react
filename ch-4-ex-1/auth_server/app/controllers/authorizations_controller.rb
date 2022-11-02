# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class AuthorizationsController < ApplicationController
  skip_forgery_protection except: :authorize
  after_action :destroy_request!, only: :approve

  INVALID_SCOPE = 'invalid_scope'
  ACCESS_DENIED = 'access_denied'
  UNSUPPORTED_RESPONSE_TYPE = 'unsupported_response_type'

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
        query: query_params,
        scope: query_params[:scope]&.split(' '),
        redirect_uri:
      )

      render 'authorize'
    end
  end

  def approve
    if req.nil?
      Rails.logger.error "No authorization request matches reqid #{body_params[:reqid]}"
      render 'error', locals: { error: 'No matching authorization request' }
      return
    end

    if body_params[:approve]
      if req.response_type == 'code'
        if disallowed_scopes.present?
          Rails.logger.error "Scope(s) #{disallowed_scopes.join(', ')} not allowed"
          redirect_to build_redirect_uri({ error: INVALID_SCOPE }), status: :found
          return
        end

        code = AuthorizationCode.create!(
          user:,
          request: req,
          code: SecureRandom.hex(8),
          scope: request_scope,
          authorization_endpoint_request: query_params
        )

        uri = build_redirect_uri({ code: code.code, state: req.query['state'] })
        redirect_to uri, status: :found
        return
      elsif req.response_type == 'token'
        if disallowed_scopes.present?
          Rails.logger.error "Scope(s) #{disallowed_scopes.join(', ')} not allowed"
          redirect_to build_redirect_uri({ error: INVALID_SCOPE }), status: :found
        end

        if user.nil?
          Rails.logger.error "Unknown user #{body_params[:user]}"
          render 'error', locals: { error: "Unknown user #{body_params[:user]}" }, status: :internal_server_error
          return
        end

        Rails.logger.info "User: #{body_params[:user]}"

        token_response = generate_token_response
        token_response[:state] = req.state if req.state.present?

        Rails.logger.info "Redirecting to redirect URI with #{token_response}"
        redirect_to build_redirect_uri(token_response), status: :found
      else
        Rails.logger.info "Unsupported response type '#{req.response_type}'"
        redirect_to build_redirect_uri({ error: UNSUPPORTED_RESPONSE_TYPE }), status: :found
      end
    else
      Rails.logger.info "User denied access for client #{req.client_id}"
      redirect_to build_redirect_uri({ error: ACCESS_DENIED }), status: :found
    end
  end

  private

  attr_reader :client_id

  def build_redirect_uri(query = {})
    qs = CGI.parse(redirect_uri.query || '').merge(query)
    redirect_uri.query = URI.encode_www_form(qs)

    redirect_uri.to_s
  end

  def redirect_uri
    @redirect_uri ||= req.present? ? URI.parse(req.redirect_uri) : URI.parse(query_params[:redirect_uri])
  end

  def client
    @client ||= req.present? ? req.client : Client.find_by(client_id:)
  end

  def req
    @req ||= Request.find_by(reqid: body_params[:reqid])
  end

  def user
    @user ||= User.find_by(sub: body_params[:user])
  end

  def generate_token_response
    access_token = SecureRandom.hex(32)

    AccessToken.create!(
      client:,
      user:,
      token: access_token,
      token_type: 'Bearer',
      scope: client.scope
    )

    Rails.logger.info "Issuing access token '#{access_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{client.scope.join(' ')}'"

    refresh_token = RefreshToken.for_client_and_user(client, user)&.token

    if refresh_token.nil?
      refresh_token = SecureRandom.hex(16)

      Rails.logger.info "Issuing refresh token '#{refresh_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{client.scope.join(' ')}'"

      RefreshToken.create!(
        client:,
        user:,
        token: refresh_token,
        scope: client.scope
      )
    end

    scope = client.scope.join(' ')

    { access_token:, refresh_token:, scope:, token_type: 'Bearer', client_id: client.client_id, user: user.sub }
  end

  def request_scope
    @request_scope ||=
      if query_params[:scope]
       query_params[:scope].split(' ') || []
      else
       body_params
         .keys
         .filter_map {|key| key.to_s.gsub('scope_', '') if key.to_s.start_with?('scope_') }
      end
  end

  def disallowed_scopes
    request_scope - client.scope
  end

  def destroy_request!
    req&.destroy!
  end
end