# frozen_string_literal: true

class AccessTokensController < ApplicationController
  def token
    if AccessToken.count == 0
      head :no_content
      return
    end

    render json: { token: AccessToken.last }, status: :ok
  end
end
