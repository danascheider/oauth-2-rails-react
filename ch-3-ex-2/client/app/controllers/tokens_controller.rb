# frozen_string_literal: true

class TokensController < ApplicationController
  def show
    token = AccessToken.last

    if token.present?
      render json: token, status: :ok
    else
      head :no_content
    end
  end
end
