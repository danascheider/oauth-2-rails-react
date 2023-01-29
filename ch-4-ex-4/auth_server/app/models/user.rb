# frozen_string_literal: true

class User < ApplicationRecord
  has_many :authorization_codes, dependent: :destroy

  validates :sub, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end