# frozen_string_literal: true

class User < ApplicationRecord
  validates :sub, presence: true, uniqueness: true
  validates :email, uniqueness: true, allow_nil: true
  validates :username, uniqueness: true, allow_nil: true
end
