# frozen_string_literal: true

module Seeds
  USER_DATA = [
    {
      sub: '9XE3-JI34-00132A',
      preferred_username: 'alice',
      name: 'Alice',
      email: 'alice.wonderland@example.com',
      email_verified: true
    },
    {
      sub: '1ZT5-OE63-57383B',
      preferred_username: 'bob',
      name: 'Bob',
      email: 'bob.loblob@example.net',
      email_verified: false
    },
    {
      sub: 'F5Q1-L6LGG-959FS',
      preferred_username: 'carol',
      name: 'Carol',
      email: 'carol.lewis@example.net',
      email_verified: true,
      username: 'clewis',
      password: 'user password!'
    }
  ].freeze

  module_function

  def seed!
    seed_client!
    seed_users!
    seed_tokens!
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

  def seed_users!
    USER_DATA.each do |data|
      User.create!(data)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
    end
  end

  def seed_tokens!
    seed_access_token!
    seed_refresh_token!
  end

  def seed_access_token!
    AccessToken.create!(
      client: Client.first,
      user: User.first,
      token: 'd8563a93b45c4400bae67c384b3f9968fcc013e3b1d180e03dc4fb3154011888',
      token_type: 'Bearer',
      scope: %w[fruit veggies meats],
      expires_at: Time.now
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
  end

  def seed_refresh_token!
    RefreshToken.create!(
      client: Client.first,
      user: User.first,
      token: '5f3a4fc620cbdb3e12a059ca83dcdb28',
      scope: %w[fruit veggies meats]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
  end
end

Seeds.seed!