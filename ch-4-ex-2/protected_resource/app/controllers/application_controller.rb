# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  attr_reader :access_token

  def query_params
    request.query_parameters
  end

  def body_params
    request.body_parameters
  end

  def get_access_token
    auth_header = request.headers['Authorization']
    if auth_header && auth_header.downcase.start_with?('bearer ')
      token = auth_header.gsub(/bearer /i, '')
    else
      token = body_params[:access_token] || query_params[:access_token]
    end

    @access_token = AccessToken.find_by(token:)
  end

  def require_access_token
    head :unauthorized unless access_token.present?
  end
end
