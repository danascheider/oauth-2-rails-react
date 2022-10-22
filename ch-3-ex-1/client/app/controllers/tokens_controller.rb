# frozen_string_literal: true

class TokensController < ApplicationController
  def show
    render json: AccessToken.last, status: :ok
  end
end