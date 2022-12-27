# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class AuthorizeService
    def initialize(controller, query_params: {}, body_params: {})
      @controller = controller
      @query_params = query_params
      @body_params = body_params
    end

    def perform
      if client.nil?
        Rails.logger.error "Unknown client '#{query_params[:client_id]}'"
        controller.render 'error', locals: { error: 'Unknown client' }
        return
      elsif client.redirect_uris.exclude?(redirect_uri&.to_s)
        Rails.logger.error "Mismatched redirect URI: expected '#{client.redirect_uris}', got '#{redirect_uri}'"
        controller.render 'error', locals: { error: 'Invalid redirect URI' }
        return
      else
        if disallowed_scopes.present?
          Rails.logger.error "Invalid scope(s) requested: #{disallowed_scopes.join(', ')}"

          query = CGI.parse(redirect_uri.query || '')
          query['error'] = AuthorizationsController::INVALID_SCOPE
          redirect_uri.query = URI.encode_www_form(query)

          controller.redirect_to redirect_uri, status: :found
          return
        end

        @req = Request.create!(
          client:,
          reqid: SecureRandom.hex(8),
          query: query_params,
          scope: query_params[:scope]&.split(' '),
          redirect_uri:
        )

        controller.render 'authorize'
      end
    end

    private

    attr_reader :controller, :query_params, :body_params

    def client
      @client ||= Client.find_by(client_id: query_params[:client_id])
    end

    def redirect_uri
      @redirect_uri ||= URI.parse(query_params[:redirect_uri]) if query_params[:redirect_uri]
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
  end
end