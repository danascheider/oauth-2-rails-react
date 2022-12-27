# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Client.find_or_create_by!(
  client_id: 'oauth-client-1',
  client_secret: 'oauth-client-secret-1',
  redirect_uris: ['http://localhost:4000/callback', 'http://localhost:4000/resource'],
  scope: %w[read write delete]
)