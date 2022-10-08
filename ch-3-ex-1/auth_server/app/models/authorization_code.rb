# frozen_string_literal: true

class AuthorizationCode < ApplicationRecord
  validates :code, presence: true, uniqueness: true
end
