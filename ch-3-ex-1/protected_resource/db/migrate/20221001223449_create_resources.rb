# frozen_string_literal: true

class CreateResources < ActiveRecord::Migration[7.0]
  def change
    create_table :resources do |t|
      t.string :name, null: false
      t.string :description

      t.timestamps
    end
  end
end
