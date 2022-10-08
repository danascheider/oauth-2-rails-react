# frozen_string_literal: true

class Client < ApplicationRecord
  has_many :requests, foreign_key: 'client_id', primary_key: 'client_id'
  has_many :access_tokens, foreign_key: 'client_id', primary_key: 'client_id'

  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validates :redirect_uris, presence: true
end
