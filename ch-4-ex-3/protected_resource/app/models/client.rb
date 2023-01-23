# frozen_string_literal: true

class Client < SharedModel
  has_many :access_tokens,
           foreign_key: 'client_id',
           primary_key: 'client_id',
           dependent: :destroy
end