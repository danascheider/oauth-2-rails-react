# frozen_string_literal: true

class CreateRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :requests do |t|
      t.string :reqid, null: false, unique: true
      t.string :query, null: false
      t.string :client_id, foreign_key: true, null: false
      t.string :scope, default: [], array: true
      t.string :redirect_uri, null: false

      t.index :reqid, unique: true

      t.timestamps
    end
  end
end
