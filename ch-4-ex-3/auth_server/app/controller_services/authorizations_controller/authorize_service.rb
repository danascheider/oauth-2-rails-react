# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  class AuthorizeService
    def initialize(controller, query_params:)
      @controller = controller
      @query_params = query_params
    end

    def perform
      if client.nil?
        Rails.logger.error "Unknown client '#{query_params[:client_id]}'"
        controller.render 'error', locals: { error: 'Unknown client' }
      end
    end

    private

    attr_reader :controller, :query_params

    def client
      @client ||= Client.find_by(client_id: query_params[:client_id])
    end
  end
end