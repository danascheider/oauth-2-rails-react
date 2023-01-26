# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:sub) {|n| "user-#{n}" }
    sequence(:email) {|n| "user-#{n}@example.com" }
    name { 'Alice' }
  end
end
