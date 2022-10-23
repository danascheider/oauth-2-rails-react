# frozen_string_literal: true

class Client < ApplicationRecord
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validates :scope, presence: true, unless: :scope_is_empty_array?
  validates :redirect_uris, presence: true

  private

  def scope_is_empty_array?
    scope == []
  end
end
