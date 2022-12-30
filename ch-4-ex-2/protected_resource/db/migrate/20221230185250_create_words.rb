# frozen_string_literal: true

class CreateWords < ActiveRecord::Migration[7.0]
  def change
    create_table :words do |t|
      t.string :word, null: false

      t.timestamps
    end
  end
end
