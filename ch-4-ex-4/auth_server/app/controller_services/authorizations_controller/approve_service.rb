# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class ApproveService
    def initialize(controller, body_params:)
      @controller = controller
      @body_params = body_params
    end

    def perform
      if req.nil?
        Rails.logger.error "No matching authorization request for reqid '#{body_params[:reqid]}'"
        controller.render 'error', locals: { error: 'No matching authorization request' }, status: :bad_request
        return
      end

      if body_params[:approve]
        # In the book's example, this code is inside the below conditional but occurs in each
        # branch, so I've moved it outside the conditional to remove the duplication.
        if disallowed_scopes.any?
          add_query(error: AuthorizationsController::INVALID_SCOPE)

          Rails.logger.error "Invalid scope(s) #{disallowed_scopes.join(',')}"
          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
          req.destroy!
          return
        end

        if user.nil?
          Rails.logger.error "Unknown user '#{body_params[:user]}'"

          # According to Okta's docs on OAuth 2, the controller should only render the
          # error page if the client_id or redirect_uri is invalid. Otherwise, it should
          # redirect to the redirect_uri with the given error. However, the book does it
          # this way, so this is how I'm doing it too.
          #
          # More info: https://www.oauth.com/oauth2-servers/authorization/the-authorization-response/
          controller.render 'error',
                            locals: { error: "Unknown user '#{body_params[:user]}'" },
                            status: :internal_server_error
          req.destroy!
          return
        end

        Rails.logger.info "User '#{user.sub}'"

        if body_params[:response_type] == 'code'
          code = SecureRandom.hex(8)

          AuthorizationCode.create!(
            client: req.client,
            user:,
            code:,
            scope: req.scope,
            expires_at: Time.now + 30.seconds
          )

          Rails.logger.info "Issuing authorization code '#{code}' for client '#{req.client_id}' and user '#{user.sub}'"

          response_params = { code: }
          response_params[:state] = req.state if req.state.present?

          add_query(**response_params)
          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
        else
          add_query(error: AuthorizationsController::UNSUPPORTED_RESPONSE_TYPE)
          Rails.logger.error "Unsupported response type '#{body_params[:response_type]}'"
          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
        end
      else
        add_query(error: AuthorizationsController::ACCESS_DENIED)
        Rails.logger.error "User denied access for client '#{req.client_id}'"
        controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
      end

      req.destroy!
    end

    private

    attr_reader :controller, :body_params

    def req
      @req ||= Request.find_by(reqid: body_params[:reqid])
    end

    def user
      @user ||= User.find_by(sub: body_params[:user])
    end

    def redirect_uri
      @redirect_uri ||= URI.parse(req&.redirect_uri)
    end

    def add_query(**params)
      query = CGI.parse(redirect_uri.query || '').merge(params)
      redirect_uri.query = URI.encode_www_form(query)
    end

    def request_scope
      @request_scope ||= body_params
                           .to_a
                           .map {|arr| arr.first.to_s.gsub('scope_', '') if arr.first.to_s.start_with?('scope_') && arr.last.to_i > 0 }
                           .compact
    end

    def disallowed_scopes
      request_scope - req.client.scope
    end
  end
end