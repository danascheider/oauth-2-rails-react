# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  def query_params
    request.query_parameters
  end

  def body_params
    request.request_parameters
  end
end
