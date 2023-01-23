# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    client
    user
    sequence(:token) { SecureRandom.hex(32) }
    token_type { 'Bearer' }
    scope { %w[fruit veggies] }
    expires_at { Time.now + 1.minute }
  end
end