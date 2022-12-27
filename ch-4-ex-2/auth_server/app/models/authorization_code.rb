# frozen_string_literal: true

class AuthorizationCode < ApplicationRecord
  belongs_to :user
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'
end
