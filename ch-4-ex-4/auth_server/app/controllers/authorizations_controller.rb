# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  ACCESS_DENIED = 'access_denied'
  INVALID_SCOPE = 'invalid_scope'

  def authorize
    AuthorizeService.new(self, query_params:).perform
  end

  def approve
    ApproveService.new(self, body_params:).perform
  end

  def token
  end
end
