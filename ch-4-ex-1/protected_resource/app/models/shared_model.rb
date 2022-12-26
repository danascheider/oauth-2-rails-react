# frozen_string_literal: true

class SharedModel < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { reading: :shared }
  establish_connection :shared

  def readonly?
    true
  end

  def destroy
    raise ActiveRecord::ReadOnlyRecord.new("Protected resource cannot manage #{pluralized_model_name}.")
  end

  def delete
    raise ActiveRecord::ReadOnlyRecord.new("Protected resource cannot manage #{pluralized_model_name}.")
  end

  private

  def pluralized_model_name
    self.class.to_s.underscore.humanize.downcase.pluralize
  end
end