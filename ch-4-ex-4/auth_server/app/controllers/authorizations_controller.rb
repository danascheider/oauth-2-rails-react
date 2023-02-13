# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :token
  before_action :identify_client, only: :token

  ACCESS_DENIED = 'access_denied'
  INVALID_SCOPE = 'invalid_scope'
  INVALID_CLIENT = 'invalid_client'
  UNSUPPORTED_RESPONSE_TYPE = 'unsupported_response_type'

  def authorize
    AuthorizeService.new(self, query_params:).perform
  end

  def approve
    ApproveService.new(self, body_params:).perform
  end

  def token
  end

  private

  attr_reader :client

  def identify_client
    auth_header = request.headers['Authorization']

    if auth_header.present?
      client_id, client_secret = Base64
                                   .decode64(auth_header.gsub(/basic /i, ''))
                                   .split(':')
                                   .map {|string| CGI.unescape(string) }
    end

    if body_params[:client_id]
      if client_id.present?
        Rails.logger.error 'Client attempted to authenticate with multiple methods'
        render json: { error: INVALID_CLIENT }, status: :unauthorized
        return
      end

      client_id = body_params[:client_id]
      client_secret = body_params[:client_secret]
    end

    @client = Client.find_by(client_id:)

    if @client.nil?
      Rails.logger.error "Unknown client '#{client_id}'"
      render json: { error: INVALID_CLIENT }, status: :unauthorized
      return
    end

    if client_secret != @client.client_secret
      Rails.logger.error "Mismatched client secret, expected '#{@client.client_secret}', got '#{client_secret}'"
      render json: { error: INVALID_CLIENT }, status: :unauthorized
      return
    end
  end
end
