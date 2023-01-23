# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:sub) { SecureRandom.uuid }
    sequence(:email) {|n| "user#{n}@example.com" }
  end
end