# frozen_string_literal: true

class CreateRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :requests do |t|
      t.string :reqid, null: false, unique: true
      t.json :query

      t.index :reqid, unique: true

      t.timestamps
    end
  end
end
