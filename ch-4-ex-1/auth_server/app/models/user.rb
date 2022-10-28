# frozen_string_literal: true

class User < ApplicationRecord
  has_one :authorization_code, dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy

  validates :sub, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :email_verified, presence: true, unless: :email_not_verified? # NOT NULL
  validates :username, uniqueness: true, allow_nil: true

  private

  def email_not_verified?
    email_verified == false
  end
end
