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
      email: 'bob.loblob@example.com',
      email_verified: false
    },
    {
      sub: 'F5Q1-L6LGG-959FS',
      preferred_username: 'carol',
      name: 'Carol',
      email: 'carol.lewis@example.com',
      email_verified: true,
      username: 'clewis',
      password: 'user password!'
    }
  ]

  module_function

  def seed!
    seed_client!
    seed_users!
  end

  def seed_client!
    Client.create!(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-secret-1',
      scope: [],
      redirect_uris: ['http://localhost:4000/callback']
    )
  rescue ActiveRecord::RecordInvalid
    Rails.logger.debug 'Client already exists'
  end

  def seed_users!
    USER_DATA.each do |fields|
      User.create!(fields)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.debug "User '#{fields[:name]}' invalid: #{e.message}"
    end
  end
end

Seeds.seed!