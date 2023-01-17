# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :token, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :empty_scope?
  validates :user_id, uniqueness: { scope: :client_id, message: 'must be unique per client' }

  private

  def empty_scope?
    scope == []
  end
end
