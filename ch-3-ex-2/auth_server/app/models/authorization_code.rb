# frozen_string_literal: true

class AuthorizationCode < ApplicationRecord
  # TODO: Should the authorization code have a client ID associated?

  validates :code, presence: true, uniqueness: true
  validates :scope, presence: true
end
