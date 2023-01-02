# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    sequence(:client_id) {|n| "oauth-client-#{n}" }
    client_secret { 'client-secret' }
    scope { %w[fruit veggies meats] }
    redirect_uris { ['http://example.com/callback'] }
  end
end