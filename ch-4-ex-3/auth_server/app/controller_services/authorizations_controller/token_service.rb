# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class TokenService
    include TokenHelper

    def initialize(controller, client:, body_params:)
      @controller = controller
      @client = client
      @body_params = body_params
    end

    def perform
      case body_params[:grant_type]
      when 'authorization_code'
        perform_authorization_code_grant
      when 'client_credentials'
        perform_client_credentials_grant
      when 'refresh_token'
        perform_refresh_token_grant
      when 'password'
        perform_password_grant
      else
        Rails.logger.error "Unknown grant type '#{body_params[:grant_type]}'"
        controller.render json: { error: AuthorizationsController::UNSUPPORTED_GRANT_TYPE }, status: :bad_request
        return
      end
    end

    private

    attr_reader :controller, :client, :body_params

    def perform_authorization_code_grant
      authorization_code = AuthorizationCode.find_by(code: body_params[:code])

      if authorization_code.present?
        if authorization_code.client == client
          tokens = generate_token_response(
            client:,
            user: authorization_code.user,
            scope: authorization_code.scope,
            generate_refresh_token: true
          )

          Rails.logger.info "Issued tokens for code '#{body_params[:code]}'"

          controller.render json: tokens, status: :ok
        else
          Rails.logger.error "Client mismatch, expected '#{authorization_code.client_id}', got '#{client.client_id}'"
          controller.render json: { error: AuthorizationsController::INVALID_GRANT }, status: :bad_request
        end

        authorization_code.destroy!
      else
        Rails.logger.error "Unknown code '#{body_params[:code]}'"
        controller.render json: { error: AuthorizationsController::INVALID_GRANT }, status: :bad_request
      end
    end

    def perform_client_credentials_grant
      if disallowed_scopes.any?
        Rails.logger.error "Invalid scope(s): #{disallowed_scopes.join(', ')}"
        controller.render json: { error: AuthorizationsController::INVALID_SCOPE }, status: :bad_request
        return
      end

      tokens = generate_token_response(client:, scope: request_scope)

      controller.render json: tokens.except(:client_id), status: :ok
    end

    def perform_refresh_token_grant
      refresh_token = RefreshToken.find_by(token: body_params[:refresh_token])

      if refresh_token.nil?
        Rails.logger.error 'No matching refresh token was found.'
        controller.head :unauthorized
        return
      end

      if refresh_token.client != client
        Rails.logger.error "Invalid client using a refresh token, expected '#{refresh_token.client_id}', got '#{client.client_id}'"
        controller.head :bad_request
        return
      end

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

      controller.render json: {
                                access_token:,
                                refresh_token: body_params[:refresh_token],
                                token_type: 'Bearer',
                                scope: refresh_token.scope.join(' ')
                              },
                        status: :ok
    end

    def perform_password_grant
      user = User.find_by(username: body_params[:username])

      if user.nil?
        Rails.logger.error "Unknown user '#{body_params[:username]}'"
        controller.render json: { error: AuthorizationsController::INVALID_GRANT }, status: :unauthorized
        return
      end

      Rails.logger.info "User is '#{body_params[:username]}'"

      if user.password.blank?
        Rails.logger.error 'Attempted password grant type but user has no password'
        controller.render json: { error: AuthorizationsController::INVALID_GRANT }, status: :unauthorized
        return
      end

      if body_params[:password] != user.password
        Rails.logger.error "Mismatched resource owner password, expected '#{user.password}', got '#{body_params[:password]}'"
        controller.render json: { error: AuthorizationsController::INVALID_GRANT }, status: :unauthorized
        return
      end

      if disallowed_scopes.any?
        Rails.logger.error "Invalid scope(s): #{disallowed_scopes.join(', ')}"
        controller.render json: { error: AuthorizationsController::INVALID_SCOPE }, status: :bad_request
        return
      end

      token_response = generate_token_response(client:, user:, scope: request_scope)
      controller.render json: token_response, status: :ok
    end

    def request_scope
      body_params[:scope]&.split(' ') || []
    end

    def disallowed_scopes
      request_scope - client.scope
    end
  end
end