# frozen_string_literal: true

class Client < ApplicationRecord
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validates :scope, presence: true, unless: :empty_scope?
  validates :redirect_uris, presence: true

  private

  def empty_scope?
    scope == []
  end
end
