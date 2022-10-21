# frozen_string_literal: true

module Seeds
  module_function

  def seed!
    client = Client.find_or_create_by!(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-secret-1',
      scope: %w[foo bar],
      redirect_uris: ['http://localhost:4000/callback']
    )

    # The database is initially seeded with an expired access token for the client.
    # The client is also set up with initial data that includes this same token as
    # well as the refresh token below.
    AccessToken.create!(
      client:,
      token: '591aa348f82c1d036549c0c88a514e295a80304c30bf9e3993bb6662f693c515',
      scope: 'foo bar',
      expires_at: 1.minute.ago
    )

    RefreshToken.create!(
      client:,
      token: '1acef900088388b5b48c25d205cf79a0',
      scope: 'foo bar'
    )
  end
end

Seeds.seed!