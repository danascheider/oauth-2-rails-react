# frozen_string_literal: true

class Client < ApplicationRecord
  VALID_SCOPES = %w[read write delete].freeze

  has_many :requests, foreign_key: 'client_id', primary_key: 'client_id', dependent: :destroy
  has_many :authorization_codes, foreign_key: 'client_id', primary_key: 'client_id', dependent: :destroy
  has_many :access_tokens, foreign_key: 'client_id', primary_key: 'client_id', dependent: :destroy

  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validates :redirect_uris, presence: true

  validate :validate_scopes, unless: :all_scopes_valid?

  private

  def validate_scopes
    errors.add(:scope, "Invalid scope: #{scope - VALID_SCOPES}")
  end

  def all_scopes_valid?
    scope.all? {|s| VALID_SCOPES.include?(s) }
  end
end
