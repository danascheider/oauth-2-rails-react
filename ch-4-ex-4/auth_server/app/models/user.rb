# frozen_string_literal: true

class User < ApplicationRecord
  validates :sub, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
