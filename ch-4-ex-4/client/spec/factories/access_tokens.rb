# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    sequence(:access_token) { SecureRandom.hex(32) }
    sequence(:refresh_token) { SecureRandom.hex(16) }
    scope { %w[movies foods music] }
    token_type { 'Bearer' }
    user { '9XE3-JI34-00132A' }
  end
end
