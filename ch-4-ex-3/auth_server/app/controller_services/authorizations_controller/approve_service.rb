# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class ApproveService
    include TokenHelper

    def initialize(controller, body_params:)
      @controller = controller
      @body_params = body_params
    end

    def perform
      if req.nil?
        Rails.logger.error "No matching authorization request for reqid '#{body_params[:reqid]}'"
        controller.render 'error', locals: { error: 'No matching authorization request' }
        return
      end

      if body_params[:approve]
        # In the book's example, this code is inside the below conditional but occurs in each
        # branch, so I've moved it outside the conditional to remove the duplication.
        if disallowed_scopes.present?
          redirect_uri.query = URI.encode_www_form({ error: AuthorizationsController::INVALID_SCOPE })

          Rails.logger.error "Invalid scope(s) #{disallowed_scopes.join(',')}"
          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true

          req.destroy!

          return
        end

        # This is also found inside the conditional below in the book's examples. Unlike the above
        # code, it only occurs in the second branch (if the response_type is 'token'). However, I'm
        # not sure omitting it from the first branch was intentional since there should be a user
        # for both 'code' and 'token' response types. Note that this also changes the behaviour when
        # the response type is invalid, since the code in that branch will never run if the user
        # is missing. This behaviour is reflected in the RSpec tests.
        if user.nil?
          Rails.logger.error "Unknown user '#{body_params[:user]}'"
          controller.render(
            'error',
            locals: { error: "Unknown user '#{body_params[:user]}'" },
            status: :internal_server_error
          )

          req.destroy!

          return
        end

        Rails.logger.info "User '#{user.sub}'"

        if req.response_type == 'code'
          code = SecureRandom.hex(8)
          AuthorizationCode.create!(
            client:,
            user:,
            code:,
            scope: request_scope,
            authorization_endpoint_request: req.attributes
          )

          query_params = { code: }
          query_params[:state] = req.state if req.state.present?

          redirect_uri.query = URI.encode_www_form(query_params)

          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
        elsif req.response_type == 'token'
          token_response = generate_token_response(client:, user:, scope: req.scope, generate_refresh_token: true)
          token_response[:state] = req.state if req.state.present?

          redirect_uri.query = URI.encode_www_form(token_response)

          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
        else
          redirect_uri.query = URI.encode_www_form({ error: AuthorizationsController::UNSUPPORTED_RESPONSE_TYPE })

          Rails.logger.error "Unsupported response type '#{req.response_type}'"
          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
        end
      else
        # Note: If the redirect URI already has a query string, this code will replace it with the
        #       access_denied error. This is fixed in exercise 4-4 so the error is appended to an
        #       existing query string, if any.
        redirect_uri.query = URI.encode_www_form({ error: AuthorizationsController::ACCESS_DENIED })

        Rails.logger.info "User denied access for client '#{req.client_id}'"
        controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
      end

      req.destroy!
    end

    private

    attr_reader :controller, :body_params

    def req
      @req ||= Request.find_by(reqid: body_params[:reqid])
    end

    def client
      @client ||= req&.client
    end

    def user
      @user ||= User.find_by(sub: body_params[:user])
    end

    def redirect_uri
      @redirect_uri ||= URI.parse(req&.redirect_uri)
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
  end
end