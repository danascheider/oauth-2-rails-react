# frozen_string_literal: true

FactoryBot.define do
  factory :request do
    client
    reqid { SecureRandom.hex(8) }
    query { { foo: 'bar' } }
    scope { %w[fruit veggies] }
    redirect_uri { 'https://example.com/callback' }
  end
end
