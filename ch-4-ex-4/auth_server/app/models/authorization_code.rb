# frozen_string_literal: true

class AuthorizationCode < ApplicationRecord
  belongs_to :user
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :code, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :empty_scope?
  validate :limit_scopes

  private

  def empty_scope?
    scope == []
  end

  def limit_scopes
    return if scope.nil?

    if (scope - client.scope).any?
      errors.add(:scope, "can't include scopes not available to associated client")
    end
  end
end
