# frozen_string_literal: true

class User < SharedModel
  has_many :access_tokens, dependent: :destroy
end