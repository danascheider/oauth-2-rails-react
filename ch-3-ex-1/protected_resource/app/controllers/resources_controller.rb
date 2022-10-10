# frozen_string_literal: true

class ResourcesController < ApplicationController
  before_action :set_token

  attr_reader :token

  def index
    if access_token
      render json: Resource.all, status: :ok
    else
      Rails.logger.error "Unable to find matching access token #{token}"
      head :unauthorized
    end
  end

  def show
    if access_token
      render json: resource, status: :ok
    else
      Rails.logger.error "Unable to find matching access token #{token}"
      head :unauthorized
    end
  end

  private

  def resource
    @resource ||= Resource.find(params[:id])
  end

  def set_token
    auth_header = request.headers['Authorization']

    @token = if auth_header && auth_header.start_with?(/bearer /i)
                auth_header.gsub(/bearer /i, '')
              # In the original Express app, it first checks post body params and
              # then query params - since all either does is assign the value to this
              # instance variable, I don't think it matters to differentiate here
              elsif params[:access_token]
                params[:access_token]
              end
  end

  def access_token
    # Only log the first time the method is called
    Rails.logger.info "Attempting to authorize with token #{token}" unless defined?(@access_token)

    @access_token ||= AccessToken.find_by(token:)
  end
end
