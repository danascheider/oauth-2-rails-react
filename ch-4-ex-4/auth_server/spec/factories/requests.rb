# frozen_string_literal: true

FactoryBot.define do
  factory :request do
    client
    sequence(:reqid) { SecureRandom.hex(8) }
    sequence(:state) { SecureRandom.hex(8) }
    response_type { 'code' }
    scope { %w[foods movies music] }
    redirect_uri { 'https://example.com/callback' }
  end
end
