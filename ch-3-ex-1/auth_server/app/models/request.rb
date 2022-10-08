# frozen_string_literal: true

class Request < ApplicationRecord
  # We want to the foreign key to get the client record by its `client_id` attribute
  # and not its `id`
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :reqid, presence: true, uniqueness: true
  validates :query, presence: true
  validates :redirect_uri, presence: true
end
