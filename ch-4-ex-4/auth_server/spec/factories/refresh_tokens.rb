# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    user
    client
    sequence(:token) { SecureRandom.hex(16) }
    scope { %w[movies foods music] }

    before(:create) do |token, evaluator|
      disallowed_scopes = token.scope - token.client.scope
      token.scope -= disallowed_scopes
    end
  end
end
