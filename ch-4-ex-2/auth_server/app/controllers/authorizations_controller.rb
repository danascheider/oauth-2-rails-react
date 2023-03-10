# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  skip_before_action :verify_authenticity_token, except: :authorize

  INVALID_SCOPE = 'invalid_scope'
  ACCESS_DENIED = 'access_denied'
  UNSUPPORTED_RESPONSE_TYPE = 'unsupported_response_type'

  def authorize
    AuthorizeService.new(self, query_params:).perform
  end

  def approve
    ApproveService.new(self, query_params:, body_params:).perform
  end

  def token
    TokenService.new(
      self,
      query_params:,
      body_params:,
      auth_header: request.headers['Authorization']
    ).perform
  end
end
