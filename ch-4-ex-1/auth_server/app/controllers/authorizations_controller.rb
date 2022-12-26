# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'

class AuthorizationsController < ApplicationController
  skip_forgery_protection except: :authorize
  after_action :destroy_request!, only: :approve
  after_action :destroy_authorization_code!, only: :token

  INVALID_SCOPE = 'invalid_scope'
  INVALID_GRANT = 'invalid_grant'
  ACCESS_DENIED = 'access_denied'
  UNSUPPORTED_RESPONSE_TYPE = 'unsupported_response_type'
  UNSUPPORTED_GRANT_TYPE = 'unsupported_grant_type'

  # Accepted grant types
  AUTHORIZATION_CODE = 'authorization_code'
  CLIENT_CREDENTIALS = 'client_credentials'
  REFRESH_TOKEN = 'refresh_token'
  PASSWORD = 'password'

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

  def token
    identify_client_for_token_request

    if body_params[:grant_type] == AUTHORIZATION_CODE
      if authorization_code.present?
        if code.client == client
          token_response = generate_token_response(
                                                    scope: authorization_code.scope,
                                                    nonce: authorization_code.authorization_endpoint_request['nonce'].presence,
                                                    generate_refresh_token: true
                                                  )

          Rails.logger.info "Issued tokens for code '#{body_params[:code]}'"
          render json: token_response, status: :ok
        else
          Rails.logger.error "Client mismatch: expected '#{authorization_code.client_id}', got '#{client_id}'"
          render json: { error: INVALID_GRANT }, status: :bad_request
        end
      else
        Rails.logger.error "Unknown code '#{body_params[:code]}'"
        render json: { error: INVALID_GRANT }, status: :bad_request
      end
    elsif body_params[:grant_type] == CLIENT_CREDENTIALS
      scope = body_params[:scope]&.split(' ')
      @client = Client.find_by(client_id: query_params[:client_id])
      client_scope = client&.scope

      if (request_scope - client_scope).any?
        render json: { error: INVALID_SCOPE }, status: :bad_request
        return
      end

      access_token = SecureRandom.hex(32)

      AccessToken.create!(
        user:,
        client:,
        token: access_token,
        token_type: 'Bearer',
        scope:
      )

      Rails.logger.info "Issuing access token '#{access_token} for client ID '#{client.client_id}'"
      token_response = { access_token:, token_type: 'Bearer', scope: scope.join(' ') }

      render json: token_response, status: :ok
    elsif body_params[:grant_type] == REFRESH_TOKEN
      tokens = RefreshToken.where(token: body_params[:refresh_token])

      if tokens.count == 1
        refresh_token = tokens.first

        if refresh_token.client_id != client_id
          Rails.logger.error "Invalid client using a refresh token, expected '#{refresh_token.client_id}', got '#{client_id}'"

          tokens.destroy_all

          head :bad_request
          return
        else
          Rails.logger.info "We found a matching refresh token: '#{body_params[:refresh_token]}'"

          access_token = SecureRandom.hex(32)

          AccessToken.create!(
            client:,
            user:,
            token: access_token
          )

          Rails.logger.info "Issuing access token '#{access_token}' for refresh token '#{body_params[:refresh_token]}'"

          token_response = { access_token:, token_type: 'Bearer', refresh_token: body_params[:refresh_token] }

          render json: token_response, status: 200
        end
      else
        Rails.logger.info 'No matching refresh token was found.'
        head :unauthorized
      end
    elsif body_params[:grant_type] == PASSWORD
      if user.nil?
        Rails.logger.error "Unknown user '#{body_params[:user]}'"
        render json: { error: INVALID_GRANT }, status: :unauthorized
        return
      end

      Rails.logger.info "User is '#{body_params[:user]}'"

      password = body_params[:password]

      if user.password != password
        Rails.logger.error "Mismatched resource owner password, expected '#{user.password}', got '#{password}'"
        render json: { error: INVALID_GRANT }, status: :unauthorized
        return
      end

      if (request_scope - client.scope).any?
        Rails.logger.error "Invalid scope requested: '#{request_scope.join(' ')}'"
        render json: { error: INVALID_SCOPE }, status: :bad_request
        return
      end

      token_response = generate_token_response(scope: request_scope)

      render json: token_response, status: :ok
    else
      Rails.logger.error "Unknown grant type '#{body_params[:grant_type]}'"
      render json: { error: UNSUPPORTED_GRANT_TYPE }, status: :bad_request
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

  def authorization_code
    @authorization_code ||= AuthorizationCode.find_by(code: body_params[:code])
  end

  def credentials_from_authorization_header
    return nil if request.headers['Authorization'].blank?

    Base64
      .decode64(request.headers['Authorization'].gsub(/basic /i, ''))
      .split(':')
      .map {|string| CGI.unescape(string) }
  end

  def identify_client_for_token_request
    @client_id, client_secret = credentials_from_authorization_header

    if body_params[:client_id]
      if client_id.present?
        Rails.logger.error 'Client attempted to authenticate with multiple methods'

        render json: { error: INVALID_CLIENT }, status: :unauthorized
        return
      end

      @client_id = body_params[:client_id]
      client_secret = body_params[:client_secret]
    end

    if client.nil?
      Rails.logger.error "Unknown client #{client_id}"

      render json: { error: INVALID_CLIENT }, status: :unauthorized
      return
    end

    if client_secret != client.client_secret
      Rails.logger.error "Mismatched client secret: expected '#{client.client_secret}', got '#{client_secret}'"

      render json: { error: INVALID_CLIENT }, status: :unauthorized
    end
  end

  def generate_token_response(scope:, nonce: nil, generate_refresh_token: false)
    access_token = SecureRandom.hex(32)

    AccessToken.create!(
      client:,
      user:,
      token: access_token,
      token_type: 'Bearer',
      scope:
    )

    Rails.logger.info "Issuing access token '#{access_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{scope.join(' ')}'"

    refresh_token = RefreshToken.for_client_and_user(client, user)&.token

    # By default, a refresh token will be generated only if one doesn't exist. This behaviour
    # can be overridden, forcing a new refresh token to be created, if the `generate_refresh_token`
    # parameter is set to `true`.
    if generate_refresh_token == true || refresh_token.nil?
      refresh_token = SecureRandom.hex(16)

      Rails.logger.info "Issuing refresh token '#{refresh_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{client.scope.join(' ')}'"

      RefreshToken.create!(
        client:,
        user:,
        token: refresh_token,
        scope:
      )
    end

    { access_token:, refresh_token:, scope: scope.join(' '), token_type: 'Bearer', client_id: client.client_id, user: user.sub }.compact
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

  def destroy_authorization_code!
    authorization_code&.destroy!
  end
end