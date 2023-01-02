# frozen_string_literal: true

module Seeds
  module_function

  def seed!
    seed_client!
  end

  def seed_client!
    Client.create!(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-secret-1',
      scope: %w[fruit veggies meats],
      redirect_uris: ['http://localhost:4000/callback']
    )
  rescue ActiveRecord::RecordInvalid
    Rails.logger.info 'Client already exists.'
  end
end

Seeds.seed!