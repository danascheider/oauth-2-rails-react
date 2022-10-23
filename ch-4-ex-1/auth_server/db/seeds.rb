# frozen_string_literal: true

module Seeds
  module_function

  def seed!
    Client.find_or_create_by!(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-secret-1',
      scope: %w[foo bar],
      redirect_uris: ['http://localhost:4000/callback']
    )
  end
end

Seeds.seed!