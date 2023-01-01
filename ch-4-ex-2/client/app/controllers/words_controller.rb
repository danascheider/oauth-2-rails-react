# frozen_string_literal: true

class WordsController < ApplicationController
  before_action :verify_token

  class UnauthorizedResponse < StandardError; end

  def index
    begin
      attempts ||= 1

      resp = Faraday.get(configatron.oauth.protected_resource.uri, nil, req_headers)

      raise UnauthorizedResponse if resp.status == 401

      if resp.success?
        render json: resp.body, status: :ok
      else
        head resp.status
      end
    rescue UnauthorizedResponse
      if attempts == 1
        Rails.logger.info 'Attempting to refresh access token...'
        attempts += 1
        retry if refresh == true
      else
        Rails.logger.error 'Access token not accepted after refresh.'
        head :unauthorized
      end
    end
  end

  def create
    begin
      attempts ||= 1

      Rails.logger.info "Adding new word: '#{params[:word]}'"
      body = URI.encode_www_form({ word: params[:word] })
      resp = Faraday.post(configatron.oauth.protected_resource.uri, body, req_headers)

      raise UnauthorizedResponse.new if resp.status == 401

      if resp.success?
        render json: resp.body, status: :created
      else
        head resp.status
      end
    rescue UnauthorizedResponse
      if attempts == 1
        Rails.logger.info 'Attempting to refresh access token...'
        attempts += 1
        retry if refresh == true
      else
        Rails.logger.error 'Access token not accepted after refresh.'
        head :unauthorized
      end
    end
  end

  def destroy
    begin
      attempts ||= 1

      resp = Faraday.delete(configatron.oauth.protected_resource.uri, nil, req_headers)

      raise UnauthorizedResponse if resp.status == 401

      if resp.success?
        head :no_content
      else
        head resp.status
      end
    rescue UnauthorizedResponse
      if attempts == 1
        Rails.logger.info 'Attempting to refresh access token...'
        attempts += 1
        retry if refresh == true
      else
        Rails.logger.error 'Access token not accepted after refresh.'
        head :unauthorized
      end
    end
  end

  private

  def req_headers
    {
      'Authorization' => "Bearer #{access_token.access_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end

  def access_token
    @access_token ||= AccessToken.last
  end

  def refresh(&block)
    refresh_token = access_token.refresh_token
    access_token&.destroy!

    if refresh_token.present?
      refresh_access_token(refresh_token, &block)
    else
      render json: { error: "Server returned status #{response.status}" }, status: resp.status
    end
  end
end
