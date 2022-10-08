# frozen_string_literal: true

class AccessToken < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :token, presence: true, uniqueness: true
end
