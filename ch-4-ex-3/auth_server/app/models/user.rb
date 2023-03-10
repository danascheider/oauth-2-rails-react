# frozen_string_literal: true

class User < ApplicationRecord
  has_many :authorization_codes, dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy

  validates :sub, presence: true, uniqueness: true
  validates :email, uniqueness: true, allow_nil: true
  validates :username, uniqueness: true, allow_nil: true
end
