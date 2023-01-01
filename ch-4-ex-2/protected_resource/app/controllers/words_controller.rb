# frozen_string_literal: true

class WordsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :get_access_token
  before_action :require_access_token

  def index
    if access_token.scope.include?('read')
      render json: { words: Word.all.pluck(:word), timestamp: Time.zone.now }, status: :ok
    else
      set_authentication_error('read')
      head :forbidden
    end
  end

  def create
    if access_token.scope.include?('write')
      Word.create!(word: body_params[:word]) if body_params[:word]

      # Ordinarily I would place this inside the `if body_params[:word]` conditional
      # and use a different response if no `word` param is included, but this is the
      # logic in the book so I'm sticking with it.
      head :created
    else
      set_authentication_error('write')
      head :forbidden
    end
  end

  def destroy
    if access_token.scope.include?('delete')
      Word.last&.destroy!
      head :no_content
    else
      set_authentication_error('delete')
      head :forbidden
    end
  end

  private

  def set_authentication_error(scope)
    response.set_header('WWW-Authenticate', "Bearer realm=localhost:4002, error=\"insufficient_scope\", scope=\"#{scope}\"")
  end
end
