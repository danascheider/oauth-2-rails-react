# frozen_string_literal: true

class SharedModel < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { reading: :shared }
  establish_connection :shared
end