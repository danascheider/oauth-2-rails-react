# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class ApproveService
    def initialize(controller, query_params:, body_params:)
      @controller = controller
      @query_params = query_params
      @body_params = body_params
    end

    def perform
      if req.nil?
        Rails.logger.error "No authorization request matches reqid #{body_params[:reqid]}"
        controller.render 'error', locals: { error: 'No matching authorization request' }
        return
      end

      if body_params[:approve]
        if req.response_type == 'code'
          if disallowed_scopes.present?
            Rails.logger.error "Scope(s) #{disallowed_scopes.join(', ')} not allowed"
            controller.redirect_to redirect_uri({ error: AuthorizationsController::INVALID_SCOPE }), status: :found
            return
          end

          code = SecureRandom.hex(8)

          Rails.logger.info "Saving authorization code '#{code}' for client '#{req.client_id}'"

          AuthorizationCode.create!(
            user:,
            client:,
            code:,
            scope: request_scope,
            authorization_endpoint_request: req.attributes
          )

          uri = redirect_uri({ code: code, state: req.query['state'], user: user.sub })
          controller.redirect_to uri, status: :found
        elsif req.response_type == 'token'
          if disallowed_scopes.present?
            Rails.logger.error "Scope(s) #{disallowed_scopes.join(', ')} not allowed"
            controller.redirect_to redirect_uri({ error: AuthorizationsController::INVALID_SCOPE }), status: :found
            return
          end

          if user.nil?
            Rails.logger.error "Unknown user #{body_params[:user]}"
            controller.render 'error', locals: { error: "Unknown user #{body_params[:user]}" }, status: :internal_server_error
            return
          end

          Rails.logger.info "User: #{body_params[:user]}"

          token_response = generate_token_response
          token_response[:state] = req.state if req.state.present?

          Rails.logger.info "Redirecting to redirect URI with #{token_response}"
          controller.redirect_to redirect_uri(token_response), status: :found
        else
          Rails.logger.info "Unsupported response type '#{req.response_type}'"
          controller.redirect_to redirect_uri({ error: AuthorizationsController::UNSUPPORTED_RESPONSE_TYPE }), status: :found
        end
      else
        Rails.logger.info "User denied access for client '#{req.client_id}'"
        controller.redirect_to redirect_uri({ error: AuthorizationsController::ACCESS_DENIED }), status: :found
      end
    end

    private

    attr_reader :controller, :query_params, :body_params

    def req
      @req ||= Request.find_by(reqid: body_params[:reqid])
    end

    def client
      @client ||= req.client
    end

    def user
      @user ||= User.find_by(sub: body_params[:user])
    end

    def base_redirect_uri
      @base_redirect_uri ||= URI.parse(req.redirect_uri)
    end

    def redirect_uri(query = {})
      qs = CGI.parse(base_redirect_uri.query || '').merge(query)
      base_redirect_uri.query = URI.encode_www_form(qs)

      base_redirect_uri.to_s
    end

    def request_scope
      @request_scope ||= body_params
                           .to_a
                           .map {|arr| arr.first.to_s.gsub('scope_', '') if arr.first.to_s.start_with?('scope_') && arr.last.to_i > 0 }
                           .compact
    end

    def disallowed_scopes
      request_scope - client.scope
    end

    def generate_token_response
      access_token = SecureRandom.hex(32)

      AccessToken.create!(
        client:,
        user:,
        token: access_token,
        token_type: 'Bearer',
        scope: request_scope,
        expires_at: Time.zone.now + 1.minute
      )

      Rails.logger.info "Issuing access token '#{access_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{scope.join(' ')}'"

      refresh_token = RefreshToken.for_client_and_user(client, user)&.token

      if refresh_token.nil?
        refresh_token = SecureRandom.hex(16)

        RefreshToken.create!(
          client:,
          user:,
          token: refresh_token,
          scope: request_scope
        )
      end

      { access_token:, refresh_token:, scope: request_scope.join(' '), token_type: 'Bearer', client_id: client.client_id, user: user.sub }.compact
    end
  end
end