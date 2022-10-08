# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'
require 'base64'

class AuthorizationsController < ApplicationController
  INVALID_CLIENT = 'invalid_client'
  INVALID_SCOPE = 'invalid_scope'
  INVALID_GRANT = 'invalid_grant'
  UNSUPPORTED_RESPONSE_TYPE = 'unsupported_response_type'
  UNSUPPORTED_GRANT_TYPE = 'unsupported_grant_type'
  ACCESS_DENIED = 'access_denied'

  GRANT_TYPES = {
    authorization_code: 'authorization_code',
    client_credentials: 'client_credentials',
    pkce: 'pkce',
    device_code: 'device_code',
    refresh_token: 'refresh_token'
  }.freeze

  def authorize
    # TODO: Specified as a query string param in the original Express app
    client = Client.find_by(client_id: params[:client_id])

    if client.nil?
      # TODO: Specified as a query string param in the original Express app
      Rails.logger.error "Unknown client #{params[:client_id]}"

      error = "Unknown client #{params[:client_id]}"
      render :error, locals: { error: }, status: :unauthorized
    # TODO: Specified as a query string param in the original Express app
    elsif client.redirect_uris.exclude?(params[:redirect_uri])
      Rails.logger.info "Mismatched redirect URIs, expected one of #{@client.redirect_uris}, got #{params[:redirect_uri]}"

      error = 'Mismatched redirect URI'
      render 'error', locals: { error: }, status: :forbidden
    else
      # TODO: Specified as a query string param in the original Express app
      request_scope = params[:scope]&.split(' ')&.sort || []
      client_scope = client.scope

      if (request_scope - client_scope).present?
        # TODO: Specified as a query string param in the original Express app
        url_parsed = URI.parse(params[:redirect_uri])
        query = CGI.parse(url_parsed.query || '')
        query['error'] = INVALID_SCOPE
        url_parsed.query = URI.encode_www_form(query)

        redirect_to url_parsed, status: :forbidden
      end

      req = Request.create!(
              client:,
              reqid: SecureRandom.hex(8),
              query: URI.encode_www_form(request.query_parameters),
              scope: request_scope,
              # TODO: Specified as a query string param in the original Express app
              redirect_uri: params[:redirect_uri]
            )

      render 'approve', locals: { client:, request: req, request_scope: }, status: :ok
    end
  end

  def approve
    # TODO: Specified as a post body param in the original Express app
    req = Request.find_by(reqid: params[:reqid])

    if req.nil?
      @error = 'No matching authorization request.'
      render 'error', status: :forbidden
    end

    req_attrs = req.attributes
    req.destroy!

    url_parsed = URI.parse(params[:redirect_uri])
    req_query = request.query_parameters

    # TODO: Specified as a post body param in the original Express app
    if params[:approve]
      if req_attrs[:query] == 'code'
        code = SecureRandom.hex(8)
        user = params[:user]
        resp_query = CGI.parse(url_parsed.query || '')
        client = Client.find_by(client_id: req_query[:client_id])

        # TODO: What if the client is not found?
        # TODO: What if the client does not match the client ID in the req_attributes?

        # TODO: Specified as post body params in the original Express app
        request_scope = params
                          .keys
                          .map(&:to_s) # TODO: is this necessary with ActionController::Parameters?
                          .filter_map {|key| key.gsub('scope_', '') if key.start_with?('scope_') }
        client_scope = client&.scope || []

        if (request_scope - client_scope).present?
          resp_query['error'] = INVALID_SCOPE
          url_parsed.query = URI.encode_www_form(resp_query)

          redirect_to url_parsed, status: :found
        end

        # TODO: Should authorization codes have a client ID associated?
        AuthorizationCode.create!(
          code:,
          authorization_endpoint_request: resp_query,
          scope: request_scope,
          user: user
        )

        resp_query['code'] = code
        resp_query['state'] = req_query[:state]
        url_parsed.query = URI.encode_www_form(resp_query)

        redirect_to url_parsed, status: :found
      else
        resp_query['error'] = UNSUPPORTED_RESPONSE_TYPE
        url_parsed.query = URI.encode_www_form(resp_query)

        redirect_to url_parsed, status: :found
      end
    else
      resp_query['error'] = ACCESS_DENIED
      url_parsed.query = URI.encode_www_form(resp_query)

      redirect_to url_parsed, status: :found
    end
  end

  def token
    auth = request.headers['Authorization']

    if auth.present?
      client_credentials = Base64
                             .decode64(auth.gsub(/basic /i, ''))
                             .split(':')
                             .map {|string| CGI.unescape(string) }

      # TODO: What if there are more or less than 2 elements in the array?

      client_id = client_credentials.first
      client_secret = client_credentials.last
    end

    # TODO: The original JS indicates this is a key in the request body, not a query param.
    #       I believe the book said query params are also allowed. Should we check for a query
    #       param separately or handle the case where it is a query param differently?
    if params[:client_id].present?
      if defined?(client_id)
        Rails.logger.error 'Client attempted to authenticate by multiple methods.'
        render json: { error: INVALID_CLIENT }, status: :unauthorized
      end

      client_id = params[:client_id]
      # TODO: This is presumably the same type of param (post body/query string) as the client ID?
      client_secret = params[:client_secret]
    end

    # TODO: What if client_id is still undefined or nil?

    client = Client.find_by(client_id:)

    if client.nil?
      Rails.logger.error "Unknown client #{client_id}"
      render json: { error: INVALID_CLIENT }, status: :unauthorized
    end

    if client_secret != client.client_secret
      # Just for illustration, hopefully no auth server actually logs this lol
      Rails.logger.error "Mismatched client secret, expected #{client.client_secret}, got #{client_secret}"
      render json: { error: INVALID_CLIENT }, status: :unauthorized
    end

    # TODO: Specified as a post body param in the original Express app
    if params[:grant_type] == GRANT_TYPES[:authorization_code]
      # TODO: Specified as a post body param in the original Express app
      code = AuthorizationCode.find_by(code: params[:code])

      if code.present?
        code_attrs = code.attributes
        code.destroy!

        if code_attrs[:authorization_endpoint_request][:client_id] == client_id
          token = SecureRandom.hex(32)
          scope = code_attrs[:scope]&.join(' ')

          access_token = AccessToken.new(client:, token:, scope:)

          if access_token.save
            Rails.logger.info "Issuing access token #{token} with scope '#{scope}'"

            response_body = {
              access_token: token,
              token_type: 'Bearer',
              scope:
            }

            # TODO: Specified as a post body param in the original Express app
            Rails.logger.info "Issued token for code #{params[:code]}"

            render json: response_body, status: :ok
          else
            # TODO: Handle the case where the access token cannot be saved
          end
        else
          Rails.logger.error "Client mismatch: expected #{code_attrs[:authorization_endpoint_request][:client_id]}, got #{client_id}"
          render json: { error: INVALID_GRANT }, status: :bad_request
        end
      else
        # TODO: Specified as a post body param in the original Express app
        Rails.logger.error "Unknown code #{params[:code]}"
        render json: { error: INVALID_GRANT }, status: :bad_request
      end
    else
      # TODO: Specified as a post body param in the original Express app
      Rails.logger.error "Unknown grant type #{params[:grant_type]}"
      render json: { error: UNSUPPORTED_GRANT_TYPE }, status: :bad_request
    end
  end
end
