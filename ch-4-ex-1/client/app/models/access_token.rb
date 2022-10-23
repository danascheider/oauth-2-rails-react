# frozen_string_literal: true

class AccessToken < ApplicationRecord
  TOKEN_TYPES = %w[Bearer PoP].freeze

  validates :access_token, presence: true, uniqueness: true
  validates :token_type, presence: true, inclusion: { in: TOKEN_TYPES }
  validates :scope, presence: true, unless: :empty_scope?

  private

  def empty_scope?
    scope == []
  end
end
