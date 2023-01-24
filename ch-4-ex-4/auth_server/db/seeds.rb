# frozen_string_literal: true

module Seeds
  module_function

  def seed!
    seed_client!
  end

  def seed_client!
    client = Client.new(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-secret-1',
      scope: %w[foods movies music],
      redirect_uris: ['http://localhost:4000/callback']
    )

    Rails.logger.error client.errors.full_messages unless client.save
  end
end

Seeds.seed!