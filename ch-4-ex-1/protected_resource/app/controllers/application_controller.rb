# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :get_access_token

  private

  attr_reader :access_token

  def query_params
    request.query_parameters
  end

  def body_params
    request.request_parameters
  end

  def get_access_token
    auth = request.headers['Authorization']

    if auth.present? && !auth.match?(/^bearer .*/i)
      render json: { error: "Invalid authorization header '#{auth}'" }, status: :bad_request
      return
    end

    token = auth&.gsub(/bearer /i, '') || body_params[:access_token] || query_params[:access_token]
    @access_token = AccessToken.find_by(token:)

    if access_token.present? && !access_token.expired?
      Rails.logger.info "Found a matching token: '#{token}'"
    elsif access_token&.expired?
      Rails.logger.info "Found an expired token: '#{token}'"
    else
      Rails.logger.error "No matching token was found: '#{token}'"
    end
  end

  def require_access_token
    if access_token.nil? || access_token.expired?
      head :unauthorized
      return
    end
  end
end
