# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_request do
    sequence(:state) { SecureRandom.hex(8) }
    response_type { 'code' }
    redirect_uri { 'https://example.com/callback' }
  end
end
