# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    sequence(:access_token) { SecureRandom.hex(32) }
    sequence(:refresh_token) { SecureRandom.hex(16) }
    sequence(:user) {|n| "user-#{n}" }
    scope { %w[fruit veggies meats] }
    token_type { 'Bearer' }
  end
end
