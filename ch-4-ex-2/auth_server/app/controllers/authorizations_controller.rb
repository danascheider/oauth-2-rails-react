# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  INVALID_SCOPE = 'invalid_scope'
  ACCESS_DENIED = 'access_denied'

  def authorize
    AuthorizeService.new(self, query_params:).perform
  end

  def approve
    ApproveService.new(self, query_params:, body_params:).perform
  end

  def token
  end
end
