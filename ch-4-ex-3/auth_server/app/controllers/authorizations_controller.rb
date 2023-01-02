# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :token

  def authorize
  end

  def approve
  end

  def token
  end
end
