# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_code do
    user
    client
    sequence(:code) { SecureRandom.hex(8) }
    scope { %w[movies foods music] }

    before(:create) do |auth_code, _evaluator|
      disallowed_scopes = auth_code.scope - auth_code.client.scope
      auth_code.scope -= disallowed_scopes
    end
  end
end
