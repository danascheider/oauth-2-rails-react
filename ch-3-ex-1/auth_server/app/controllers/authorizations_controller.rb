# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'securerandom'
require 'base64'

class AuthorizationsController < ApplicationController
  skip_forgery_protection

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
    client = Client.find_by(client_id: query_params[:client_id])

    if client.nil?
      Rails.logger.error "Unknown client #{query_params[:client_id]}"

      error = "Unknown client #{query_params[:client_id]}"
      render :error, locals: { error: }, status: :unauthorized
    elsif client.redirect_uris.exclude?(query_params[:redirect_uri])
      Rails.logger.info "Mismatched redirect URIs, expected one of #{client.redirect_uris}, got #{query_params[:redirect_uri]}"
      render 'error', locals: { error: 'Mismatched redirect URI' }, status: :forbidden
    else
      request_scope = query_params[:scope]&.split(' ')&.sort || []
      client_scope = client.scope

      if (request_scope - client_scope).present?
        url_parsed = URI.parse(CGI.unescape(query_params[:redirect_uri]))
        query = CGI.parse(url_parsed.query || '')
        query['error'] = INVALID_SCOPE
        url_parsed.query = URI.encode_www_form(query)

        redirect_to url_parsed, status: :found
      end

      req = Request.create!(
              client:,
              reqid: SecureRandom.hex(8),
              query: URI.encode_www_form(request.query_parameters),
              scope: request_scope,
              redirect_uri: query_params[:redirect_uri]
            )

      render 'approve', locals: { client:, request: req, request_scope: }, status: :ok
    end
  end

  def approve
    req = Request.find_by(reqid: body_params[:reqid])

    if req.nil?
      render 'error', locals: { error: 'No matching authorization request.' }, status: :forbidden
      return
    end

    req_attrs = req.attributes
    req.destroy!

    url_parsed = URI.parse(CGI.unescape(req_attrs['redirect_uri']))
    req_query = CGI.parse(req.query).map {|key, value| value.length == 1 ? [key, value[0]] : [key, value] }.to_h

    if body_params[:approve]
      resp_query = CGI.parse(url_parsed.query || '')

      if req_query['response_type'] == 'code'
        code = SecureRandom.hex(8)

        # TODO: The client in this system never actually passes this param so
        #       not sure what the authors' endgame was here and I'm also not
        #       sure if this is supposed to be a query param or a body param
        #       or whether that matters in this case.
        user = params[:user]
        client = Client.find_by(client_id: req_query['client_id'])

        # TODO: What if the client is not found?
        # TODO: What if the client does not match the client ID in the req_attributes?

        request_scope = body_params
                          .keys
                          .map(&:to_s)
                          .filter_map {|key| key.gsub('scope_', '') if key.start_with?('scope_') }
        client_scope = client&.scope || []

        if (request_scope - client_scope).present?
          Rails.logger.error 'Invalid scope - authorization code not created'

          resp_query['error'] = INVALID_SCOPE
          url_parsed.query = URI.encode_www_form(resp_query)

          redirect_to url_parsed.to_s, status: :found
          return
        end

        # TODO: Should authorization codes have a client ID associated?
        AuthorizationCode.create!(
          code:,
          authorization_endpoint_request: req_query,
          scope: request_scope,
          user:
        )

        Rails.logger.debug "Authorization code created with code #{code}"

        resp_query['code'] = code
        resp_query['state'] = req_query['state']
        url_parsed.query = URI.encode_www_form(resp_query)

        redirect_to url_parsed.to_s, status: :found
      else
        Rails.logger.error 'Unsupported response type - authorization code not created'
        resp_query['error'] = UNSUPPORTED_RESPONSE_TYPE
        url_parsed.query = URI.encode_www_form(resp_query)

        redirect_to url_parsed.to_s, status: :found
      end
    else
      Rails.logger.error 'Access denied - authorization code not created'

      resp_query['error'] = ACCESS_DENIED
      url_parsed.query = URI.encode_www_form(resp_query)

      redirect_to url_parsed.to_s, status: :found
    end
  end

  def token
    auth = request.headers['Authorization']

    if auth.present?
      client_credentials = Base64
                             .decode64(auth.gsub(/bearer /i, ''))
                             .split(':')
                             .map {|string| CGI.unescape(string) }

      # TODO: What if there are more or less than 2 elements in the array?

      client_id, client_secret = client_credentials
    end

    # TODO: The original JS indicates this is a key in the request body, not a query param.
    #       I believe the book said query params are also allowed. Should we check for a query
    #       param separately or handle the case where it is a query param differently?
    if params[:client_id].present?
      if client_id.present?
        Rails.logger.error 'Client attempted to authenticate by multiple methods.'
        render json: { error: INVALID_CLIENT }, status: :unauthorized
        return
      end

      client_id = params[:client_id]
      # TODO: This is presumably the same type of param (post body/query string) as the client ID?
      client_secret = params[:client_secret]
    end

    client = Client.find_by(client_id:)

    if client.nil?
      Rails.logger.error "Unknown client #{client_id}"
      render json: { error: INVALID_CLIENT }, status: :unauthorized
      return
    end

    if client_secret != client.client_secret
      # Just for illustration, hopefully no auth server actually logs this lol
      Rails.logger.error "Mismatched client secret, expected #{client.client_secret}, got #{client_secret}"
      render json: { error: INVALID_CLIENT }, status: :unauthorized
      return
    end

    # TODO: Specified as a post body param in the original Express app
    if body_params[:grant_type] == GRANT_TYPES[:authorization_code]

      # TODO: Specified as a post body param in the original Express app
      code = AuthorizationCode.find_by(code: body_params[:code])

      if code.present?
        code_attrs = code.attributes
        code.destroy!

        if code_attrs['authorization_endpoint_request']['client_id'] == client_id
          token = SecureRandom.hex(32)
          scope = code_attrs['scope']&.join(' ')

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
          Rails.logger.error "Client mismatch: expected #{code_attrs['authorization_endpoint_request']['client_id']}, got #{client_id}"
          render json: { error: INVALID_GRANT }, status: :bad_request
        end
      else
        # TODO: Specified as a post body param in the original Express app
        Rails.logger.error "Unknown code #{body_params[:code]}"
        render json: { error: INVALID_GRANT }, status: :bad_request
      end
    else
      # TODO: Specified as a post body param in the original Express app
      Rails.logger.error "Unknown grant type #{body_params[:grant_type]}"
      render json: { error: UNSUPPORTED_GRANT_TYPE }, status: :bad_request
    end
  end
end
