# frozen_string_literal: true

class BaseController < ApplicationController
  before_action :set_clients

  def index
  end

  private

  def set_clients
    @clients = Client.all
  end
end
