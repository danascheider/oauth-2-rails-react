# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_code do
    user
    client
    sequence(:code) { SecureRandom.hex(8) }
    scope { %w[fruit veggies] }
  end
end
