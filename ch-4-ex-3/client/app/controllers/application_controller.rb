# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def query_params
    request.query_parameters
  end
end
