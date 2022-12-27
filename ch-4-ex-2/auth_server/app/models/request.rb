# frozen_string_literal: true

class Request < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'
end
