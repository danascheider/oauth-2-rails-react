# frozen_string_literal: true

class AccessTokensController < ApplicationController
  def token
    if AccessToken.count == 0
      head :no_content
    else
      render json: AccessToken.last, status: :ok
    end
  end
end
