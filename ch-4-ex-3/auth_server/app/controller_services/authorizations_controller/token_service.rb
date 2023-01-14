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
  end
end