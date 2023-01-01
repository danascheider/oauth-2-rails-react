# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

module Seeds
  USER_DATA = [
    {
      sub: '9XE3-JI34-00132A',
      preferred_username: 'alice',
      name: 'Alice',
      email: 'alice.wonderland@example.com',
      email_verified: true
    }.freeze,
    {
      sub: '1ZT5-OE63-57383B',
      preferred_username: 'bob',
      name: 'Bob',
      email: 'bob.loblob@example.net',
      email_verified: false
    }.freeze,
    {
      sub: 'F5Q1-L6LGG-959FS',
      preferred_username: 'carol',
      name: 'Carol',
      email: 'carol.lewis@example.net',
      email_verified: true,
      username: 'carol',
      password: 'user password!'
    }.freeze
  ].freeze

  module_function

  def seed!
    seed_client!
    seed_users!
    seed_tokens!
  end

  def seed_client!
    Client.find_or_create_by!(
      client_id: 'oauth-client-1',
      client_secret: 'oauth-client-secret-1',
      redirect_uris: ['http://localhost:4000/callback', 'http://localhost:4000/words'],
      scope: %w[read write delete]
    )
  end

  def seed_users!
    USER_DATA.each do |data|
      User.create!(data)
    rescue ActiveRecord::RecordInvalid => e
      # If there is a duplicate, just move on to the next one
    end
  end

  def seed_tokens!
    AccessToken.create!(
      client: Client.first,
      user: User.first,
      token: 'a1d221ca205682a69ceaf0b0fad6ccefdced6e81d3fa4f169381c0c3b5a10a16',
      scope: %w[read write delete],
      token_type: 'Bearer',
      expires_at: Time.now
    )

    RefreshToken.create!(
      client: Client.first,
      user: User.first,
      token: 'b15b3b4bf2f10020133e805602d21178',
      scope: %w[read write delete]
    )
  end
end

Seeds.seed!