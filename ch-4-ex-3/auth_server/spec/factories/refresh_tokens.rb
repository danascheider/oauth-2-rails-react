# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    user
    client
    sequence(:token) { SecureRandom.hex(16) }
    scope { %w[fruit veggies] }
  end
end
