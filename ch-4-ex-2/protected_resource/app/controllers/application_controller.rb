# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  attr_reader :access_token

  def query_params
    request.query_parameters
  end

  def body_params
    request.request_parameters
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
    if access_token.nil?
      Rails.logger.error 'Missing access token'
      head :unauthorized
    elsif access_token.expired?
      Rails.logger.error "Access token '#{access_token.token}' is expired"
      head :unauthorized
    end
  end
end
