# frozen_string_literal: true

class ProduceController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :get_access_token
  before_action :require_access_token

  def index
    produce = { fruit: [], veggies: [], meats: [] }
    produce[:fruit] = %w[apple banana kiwi] if access_token.scope.include?('fruit')
    produce[:veggies] = %w[lettuce onion potato] if access_token.scope.include?('veggies')
    produce[:meats] = ['bacon', 'steak', 'chicken breast'] if access_token.scope.include?('meats')

    Rails.logger.info "Sending produce: #{produce}"
    render json: produce, status: :ok
  end

  private

  attr_reader :access_token

  def get_access_token
    token =
      if request.headers['Authorization']
        if request.headers['Authorization'].match(/^bearer \S+$/i)
          request.headers['Authorization'].gsub(/^bearer /i, '')
        else
          nil
        end
      else
        query_params[:access_token]
      end

    Rails.logger.info "Requested with token '#{token}'"

    @access_token = AccessToken.find_by(token:)
  end

  def require_access_token
    if access_token.nil?
      Rails.logger.error 'Missing access token'
      head :unauthorized
    elsif access_token.expired?
      Rails.logger.error "Access token '#{access_token.token}' is expired"
      head :unauthorized
    else
      Rails.logger.info "We found a matching access token: '#{access_token.token}'"
    end
  end
end
