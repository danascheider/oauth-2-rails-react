# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:sub) {|n| "user#{n}" }
    sequence(:email) {|n| "user#{n}@example.com" }
    email_verified { false }
  end
end
