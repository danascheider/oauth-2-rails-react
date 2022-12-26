# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def body_params
    request.request_parameters
  end

  def query_params
    request.query_parameters
  end
end
