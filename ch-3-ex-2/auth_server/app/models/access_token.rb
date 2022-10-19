# frozen_string_literal: true

class AccessToken < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  DEFAULT_EXPIRATION_TIME = 2.minutes

  validates :token, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :scope_is_empty_string?
  validates :expires_at, presence: true

  before_create :set_default_expiration, if: ->{ expires_at.blank? }

  private

  def scope_is_empty_string?
    scope == ''
  end

  def set_default_expiration
    self.expires_at = DEFAULT_EXPIRATION_TIME.since
  end
end
