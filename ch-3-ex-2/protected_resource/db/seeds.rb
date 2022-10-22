# frozen_string_literal: true

module Seeds
  module_function

  def seed!
    Resource.create!(
      name: 'Protected Resource',
      description: 'This data has been protected by OAuth 2.0'
    )
  end
end

Seeds.seed!