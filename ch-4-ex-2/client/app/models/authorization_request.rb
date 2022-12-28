# frozen_string_literal: true

class AuthorizationRequest < ApplicationRecord
  validates :state, presence: true, uniqueness: true
  validates :response_type, presence: true
  validates :redirect_uri, presence: true
end
