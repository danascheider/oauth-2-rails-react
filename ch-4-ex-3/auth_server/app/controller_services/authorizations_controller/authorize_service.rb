# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class AuthorizeService
    def initialize(controller, query_params:)
      @controller = controller
      @query_params = query_params
    end

    def perform
      if client.nil?
        Rails.logger.error "Unknown client '#{query_params[:client_id]}'"
        controller.render 'error', locals: { error: 'Unknown client' }
        return
      end

      if client.redirect_uris.exclude?(query_params[:redirect_uri])
        Rails.logger.error "Mismatched redirect URI, expected #{client.redirect_uris.join(',')}, got '#{query_params[:redirect_uri]}'"
        controller.render 'error', locals: { error: 'Invalid redirect URI' }
        return
      end

      if disallowed_scopes.any?
        Rails.logger.error "Invalid scope(s) #{disallowed_scopes.join(',')}"

        redirect_uri = URI.parse(query_params[:redirect_uri])
        query = CGI.parse(redirect_uri.query || '')
        query['error'] = AuthorizationsController::INVALID_SCOPE
        redirect_uri.query = URI.encode_www_form(query)

        controller.redirect_to redirect_uri.to_s, status: :found
        return
      end

      reqid = SecureRandom.hex(8)

      req = Request.create!(
        client:,
        reqid:,
        redirect_uri: query_params[:redirect_uri],
        query: query_params.to_json,
        scope: query_params[:scope]&.split(' '),
      )

      controller.render 'authorize', locals: { client:, req: }
    end

    private

    attr_reader :controller, :query_params

    def client
      @client ||= Client.find_by(client_id: query_params[:client_id])
    end

    def request_scope
      query_params[:scope].split(' ')
    end

    def disallowed_scopes
      request_scope - client.scope
    end
  end
end