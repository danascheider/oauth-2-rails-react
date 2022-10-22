# frozen_string_literal: true

class ResourcesController < ApplicationController
  skip_forgery_protection
  before_action :get_access_token

  def index
    if access_token.nil?
      Rails.logger.info 'No matching access token found'
      head :unauthorized
    elsif access_token.expired?
      Rails.logger.info "Access token '#{access_token.token}' expired #{access_token.expires_at}"
      head :unauthorized
    else
      render json: Resource.all, status: :ok
    end
  end

  private

  attr_reader :access_token

  def get_access_token
    auth = request.headers['Authorization']

    token =
      if auth.present? && auth.match(/^bearer .*/i)
        auth.gsub(/^bearer /i, '')
      elsif body_params[:access_token]
        body_params[:access_token]
      elsif query_params[:access_token]
        query_params[:access_token]
      end

    Rails.logger.debug "Incoming access token '#{token}'"
    @access_token = AccessToken.find_by(token:)
  end
end