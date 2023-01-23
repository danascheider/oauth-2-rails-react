# frozen_string_literal: true

class TokensController < ApplicationController
  def last
    if AccessToken.any?
      render json: AccessToken.last, status: :ok
    else
      head :no_content
    end
  end
end
