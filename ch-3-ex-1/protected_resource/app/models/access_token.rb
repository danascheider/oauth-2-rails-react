# frozen_string_literal: true

class AccessToken < ApplicationRecord
  connects_to database:{ reading: :shared }
end