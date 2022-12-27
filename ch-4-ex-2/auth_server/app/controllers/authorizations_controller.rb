# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  INVALID_SCOPE = 'invalid_scope'

  def authorize
    AuthorizeService.new(self, query_params:).perform
  end

  def approve
  end

  def token
  end
end
