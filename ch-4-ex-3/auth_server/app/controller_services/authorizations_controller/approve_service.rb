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
        controller.render 'error', locals: { error: 'No matching authorization request' }
        return
      end

      if body_params[:approve]
        if req.response_type == 'code'
        elsif req.response_type == 'token'
        else
          redirect_uri.query = URI.encode_www_form({ error: AuthorizationsController::UNSUPPORTED_RESPONSE_TYPE })

          Rails.logger.error "Unsupported response type '#{req.response_type}'"
          controller.redirect_to redirect_uri.to_s, status: :found, allow_other_host: true
        end
      else
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

    def redirect_uri
      @redirect_uri ||= URI.parse(req&.redirect_uri)
    end
  end
end