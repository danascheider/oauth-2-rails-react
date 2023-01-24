# frozen_string_literal: true

class AuthorizationRequest < ApplicationRecord
  URI_PATTERN = /\Ahttps?\:\/\/([_\-\w]+\.)*\w+\.?(\:\d{2,5})?(\/\w*)*(\?\S*)?(#\S*)?\z/

  validates :state, presence: true, uniqueness: true
  validates :response_type, presence: true
  validates :redirect_uri,
            presence: true,
            format: {
              with: URI_PATTERN,
              message: 'must be a valid URI'
            }
end
