# frozen_string_literal: true

class AuthorizationRequest < ApplicationRecord
  validates :state, presence: true, uniqueness: true
  validates :redirect_uri, presence: true, inclusion: { in: configatron.oauth.client.redirect_uris }
  validates :response_type, presence: true, inclusion: { in: %w[code] }
end
