# frozen_string_literal: true

class ResourcesController < ApplicationController
  before_action :require_access_token

  def index
    render json: Resource.all, status: :ok
  end
end
