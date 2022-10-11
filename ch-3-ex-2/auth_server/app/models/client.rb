# frozen_string_literal: true

class Client < ApplicationRecord
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validates :redirect_uris, presence: true
end
