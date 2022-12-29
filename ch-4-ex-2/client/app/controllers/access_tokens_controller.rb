# frozen_string_literal: true

class AccessTokensController < ApplicationController
  def token
    status = AccessToken.any? ? :ok : :no_content
    render json: AccessToken.last, status:
  end
end
