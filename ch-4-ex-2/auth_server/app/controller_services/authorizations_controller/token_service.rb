# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class TokenService
    AUTHORIZATION_CODE = 'authorization_code'
    CLIENT_CREDENTIALS = 'client_credentials'
    REFRESH_TOKEN = 'refresh_token'
    PASSWORD = 'password'

    INVALID_GRANT = 'invalid_grant'
    INVALID_SCOPE = 'invalid_scope'

    def initialize(controller, query_params:, body_params:, auth_header: nil)
      @controller = controller
      @query_params = query_params
      @body_params = body_params
      @auth_header = auth_header
    end

    def perform
      identify_client

      if body_params[:grant_type] == AUTHORIZATION_CODE
        perform_authorization_code_grant
      elsif body_params[:grant_type] == CLIENT_CREDENTIALS
        perform_client_credentials_grant
      elsif body_params[:grant_type] == REFRESH_TOKEN
        perform_refresh_token_grant
      elsif body_params[:grant_type] == PASSWORD
        perform_password_grant
      else
        Rails.logger.error "Unknown grant type '#{body_params[:grant_type]}'"
        render json: { error: UNSUPPORTED_GRANT_TYPE }, status: :bad_request
      end
    rescue StandardError => e
      Rails.logger.error e.message
    end

    private

    attr_reader :controller, :query_params, :body_params, :auth_header, :client

    def perform_authorization_code_grant
      if authorization_code.present?
        if authorization_code.client == client
          token_response = generate_token_response(
                                                    scope: authorization_code.scope,
                                                    nonce: authorization_code.authorization_endpoint_request['nonce'].presence,
                                                  )

          Rails.logger.info "Issued tokens for code '#{body_params[:code]}'"
          controller.render json: token_response, status: :ok
        else
          Rails.logger.error "Client mismatch: expected '#{authorization_code.client_id}', got '#{client_id}'"
          controller.render json: { error: INVALID_GRANT }, status: :bad_request
        end
      else
        Rails.logger.error "Unknown authorization code '#{body_params[:code]}'"

        controller.render json: { error: INVALID_GRANT }, status: :bad_request
      end
    end

    def perform_client_credentials_grant
      if disallowed_scopes.present?
        Rails.logger.error "Disallowed scope(s) requested: #{disallowed_scopes.join(', ')}"
        controller.render json: { error: INVALID_SCOPE }, status: :bad_request
        return
      end

      access_token = SecureRandom.hex(32)

      AccessToken.create!(
        user:,
        client:,
        token: access_token,
        token_type: 'Bearer',
        scope: request_scope,
        expires_at: Time.zone.now + 1.minute
      )

      Rails.logger.info "Issuing access token '#{access_token}' for client ID '#{client.client_id}'"
      token_response = { access_token:, token_type: 'Bearer', scope: scope.join(' ') }

      controller.render json: token_response, status: :ok
    end

    def perform_refresh_token_grant
      tokens = RefreshToken.where(token: body_params[:refresh_token])

      if tokens.count == 1
        refresh_token = tokens.first

        if refresh_token.client != client
          Rails.logger.error "Invalid client using a refresh token, expected '#{refresh_token.client_id}', got '#{client_id}'"
          tokens.destroy_all

          head :bad_request
          return
        else
          Rails.logger.info "We found a matching refresh token: '#{body_params[:refresh_token]}'"

          access_token = SecureRandom.hex(32)

          AccessToken.create!(
            client:,
            user: refresh_token.user,
            token: access_token,
            token_type: 'Bearer',
            scope: refresh_token.scope,
            expires_at: Time.zone.now + 1.minute
          )

          Rails.logger.info "Issuing access token '#{access_token}' for refresh token '#{body_params[:refresh_token]}'"

          token_response = { access_token:, token_type: 'Bearer', refresh_token: body_params[:refresh_token] }

          render json: token_response, status: :ok
        end
      else
        Rails.logger.info 'No matching refresh token was found.'
        head :unauthorized
      end
    end

    def perform_password_grant
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

      if disallowed_scopes.present?
        Rails.logger.error "Invalid scope(s) requested: '#{disallowed_scopes.join(' ')}'"
        render json: { error: INVALID_SCOPE }, status: :bad_request
        return
      end

      token_response = generate_token_response(scope: request_scope)

      render json: token_response, status: :ok
    end

    def identify_client
      client_id, client_secret = credentials_from_authorization_header

      if body_params[:client_id]
        if client_id.present?
          Rails.logger.error 'Client attempted to authenticate with multiple methods'

          controller.render json: { error: INVALID_CLIENT }, status: :unauthorized
          return
        end

        client_id = body_params[:client_id]
        client_secret = body_params[:client_secret]
      end

      @client = Client.find_by(client_id:)

      if @client.nil?
        Rails.logger.error "Unknown client #{client_id}"

        controller.render json: { error: INVALID_CLIENT }, status: :unauthorized
        return
      end

      if client_secret != client.client_secret
        Rails.logger.error "Mismatched client secret: expected '#{client.client_secret}', got '#{client_secret}'"

        controller.render json: { error: INVALID_CLIENT }, status: :unauthorized
      end
    end

    def authorization_code
      @authorization_code ||= AuthorizationCode.find_by(code: body_params[:code])
    end

    def user
      @user ||= User.find_by(sub: body_params[:user])
    end

    def disallowed_scopes
      request_scope - client.scope
    end

    def request_scope
      body_params[:scope].split(' ')
    end

    def credentials_from_authorization_header
      return if auth_header.blank?

      Base64
        .decode64(auth_header.gsub(/basic /i, ''))
        .split(':')
        .map {|string| CGI.unescape(string) }
    end

    def generate_token_response(scope: [], nonce: nil)
      access_token = SecureRandom.hex(32)

      AccessToken.create!(
        client:,
        user:,
        token: access_token,
        token_type: 'Bearer',
        scope:,
        expires_at: Time.zone.now + 1.minute
      )

      Rails.logger.info "Issuing access token '#{access_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{scope.join(' ')}'"

      refresh_token = RefreshToken.for_client_and_user(client, user).last&.token

      # By default, a refresh token will be generated only if one doesn't exist. This behaviour
      # can be overridden, forcing a new refresh token to be created, if the `generate_refresh_token`
      # parameter is set to `true`.
      if refresh_token.nil?
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
  end
end