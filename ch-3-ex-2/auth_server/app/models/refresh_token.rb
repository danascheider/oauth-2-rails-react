# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :token, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :scope_is_empty_string?

  private

  def scope_is_empty_string?
    scope == ''
  end
end
