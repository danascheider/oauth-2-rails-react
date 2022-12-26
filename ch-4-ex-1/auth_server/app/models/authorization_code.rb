# frozen_string_literal: true

class AuthorizationCode < ApplicationRecord
  belongs_to :user
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :code, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :empty_scope?

  private

  def empty_scope?
    scope == []
  end
end
