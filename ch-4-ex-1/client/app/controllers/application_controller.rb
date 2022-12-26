# frozen_string_literal: true

class ApplicationController < ActionController::API
  before_action :get_access_token

  private

  attr_reader :access_token

  def body_params
    request.request_parameters
  end

  def query_params
    request.query_parameters
  end

  def get_access_token
    auth = request.headers['Authorization']

    raise "Invalid authorization header '#{auth}'" if auth.present? && !auth.match?(/^bearer .*/i)

    token = auth&.gsub(/bearer /i, '') || body_params[:access_token] || query_params[:access_token]
    @access_token = AccessToken.find_by(access_token: token)

    if access_token.present?
      Rails.logger.info "Found a matching token: '#{token}'"
    else
      Rails.logger.error "No matching token was found: '#{token}'"
    end
  end

  def require_access_token
    if access_token.nil?
      head :unauthorized
      return
    end
  end
end
