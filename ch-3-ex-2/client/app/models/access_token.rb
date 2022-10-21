# frozen_string_literal: true

class AccessToken < ApplicationRecord
  TOKEN_TYPES = %w[Bearer PoP].freeze

  validates :access_token, presence: true, uniqueness: true
  validates :token_type, null: false, inclusion: { in: TOKEN_TYPES }
  validates :scope, null: false
end
