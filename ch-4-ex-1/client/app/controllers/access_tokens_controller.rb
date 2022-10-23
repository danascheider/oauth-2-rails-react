# frozen_string_literal: true

class AccessTokensController < ApplicationController
  def token
    render json: { token: AccessToken.last }, status: :ok
  end
end
