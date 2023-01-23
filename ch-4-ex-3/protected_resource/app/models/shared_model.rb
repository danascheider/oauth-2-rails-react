# frozen_string_literal: true

class SharedModel < ActiveRecord::Base
  self.abstract_class = true

  def self.database_options
    return { reading: :shared } unless Rails.env.test?

    { reading: :shared, writing: :shared }
  end

  connects_to database: self.database_options
  establish_connection :shared

  def readonly?
    !Rails.env.test?
  end

  def destroy
    raise ActiveRecord::ReadOnlyRecord.new("Protected resource cannot manage #{pluralized_model_name}.") unless Rails.env.test?

    super
  end

  def delete
    raise ActiveRecord::ReadOnlyRecord.new("Protected resource cannot manage #{pluralized_model_name}.") unless Rails.env.test?

    super
  end

  private

  def pluralized_model_name
    self.class.to_s.underscore.humanize.downcase.pluralize
  end
end