# frozen_string_literal: true

class AccessToken < ApplicationRecord
  TOKEN_TYPES = %w[Bearer PoP].freeze

  validates :access_token, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :empty_scope?
  validates :token_type, presence: true, inclusion: { in: TOKEN_TYPES }
  validates :user, presence: true, uniqueness: true

  private

  def empty_scope?
    scope == []
  end
end
