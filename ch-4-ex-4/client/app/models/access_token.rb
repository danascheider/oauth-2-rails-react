# frozen_string_literal: true

class AccessToken < ApplicationRecord
  TOKEN_TYPES = %w[Bearer PoP]

  validates :access_token, presence: true, uniqueness: true
  validates :refresh_token, uniqueness: { allow_nil: true }
  validates :scope, presence: true, unless: :empty_scope?
  validates :token_type, presence: true, inclusion: { in: TOKEN_TYPES }
  validates :user, presence: true

  private

  def empty_scope?
    scope == []
  end
end
