# frozen_string_literal: true

class CreateClients < ActiveRecord::Migration[7.0]
  def change
    create_table :clients do |t|
      t.string :client_id, null: false, unique: true
      t.string :client_secret, null: false
      t.string :redirect_uris, array: true, null: false, default: []
      t.string :scope, array: true, null: false, default: []

      t.index :client_id, unique: true

      t.timestamps
    end
  end
end
