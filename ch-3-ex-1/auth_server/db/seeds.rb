# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#

module Seeds
  module_function

  def seed!
    return if Client.find_by(client_id: 'oauth-client-1').present?

    Client.create!(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-1-secret',
      scope: %w[foo bar],
      redirect_uris: ['http://localhost:4000/callback']
    )
  end
end

Seeds.seed!