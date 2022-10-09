# frozen_string_literal: true

class ResourcesController < ApplicationController
  def fetch
    # TODO: Is this really how I'm supposed to do this for this exercise?
    #       I guess so based on the Express app...
    access_token = AccessToken.last

    if access_token.nil?
      Rails.logger.error 'Attempted to fetch protected resource but no access token was present'
      render json: { error: 'Missing access token' }, status: :unauthorized
    end

    headers = {
      'Authorization' => "Bearer #{access_token.access_token}"
    }

    resource_resp = Faraday.get(configatron.oauth.resource.endpoint, nil, headers)

    if resource_resp.success?
      resource = JSON.parse(resource_resp.body, symbolize_names: true)

      render json: { resource: }, status: :ok
    else
      render json: { error: "Server returned response code: #{resource_resp.status}" }, status: resource_resp.status
    end
  end
end
