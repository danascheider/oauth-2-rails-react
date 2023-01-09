# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    user
    client
    sequence(:token) { SecureRandom.hex(32) }
    token_type { 'Bearer' }
    scope { [] }
    expires_at { Time.zone.now + 1.minute }
  end
end
