# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

module Seeds
  module_function

  def seed!
    # The database is initially seeded with an _expired_ access token for purposes of
    # demonstration. New access tokens are valid for 2 minutes after issue.
    AccessToken.create!(
      access_token: '591aa348f82c1d036549c0c88a514e295a80304c30bf9e3993bb6662f693c515',
      refresh_token: '1acef900088388b5b48c25d205cf79a0',
      scope: %w[foo bar],
      token_type: 'Bearer'
    )
  end
end

Seeds.seed!