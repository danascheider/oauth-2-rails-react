# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    user
    client
    sequence(:token) { SecureRandom.hex(32) }
    token_type { 'Bearer' }
    scope { %w[movies foods music] }
    expires_at { Time.now + 1.minute }

    before(:create) do |access_token, _evaluator|
      disallowed_scopes = access_token.scope - access_token.client.scope
      access_token.scope -= disallowed_scopes
    end
  end
end
