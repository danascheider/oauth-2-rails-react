# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :user_id, uniqueness: { scope: :client_id }
  validates :scope, presence: true, unless: :empty_scope?

  scope :for_client_and_user, ->(client, user) { find_by(client_id: client.client_id, user_id: user.id) }

  private

  def empty_scope?
    scope == []
  end
end
