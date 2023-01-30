# frozen_string_literal: true

class AccessToken < ApplicationRecord
  TOKEN_TYPES = %w[Bearer PoP].freeze

  belongs_to :user, optional: true
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :token, presence: true, uniqueness: true
  validates :token_type, presence: true, inclusion: { in: TOKEN_TYPES }
  validates :scope, presence: true, unless: :empty_scope?
  validates :expires_at, presence: true

  validate :limit_scope

  private

  def empty_scope?
    scope == []
  end

  def limit_scope
    return if scope.nil?

    if (scope - client.scope).any?
      errors.add(:scope, 'cannot include scopes not available to client')
    end
  end
end
