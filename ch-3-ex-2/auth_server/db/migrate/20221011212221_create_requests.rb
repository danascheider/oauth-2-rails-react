# frozen_string_literal: true

class CreateRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :requests do |t|
      t.references :client,
                   null: false,
                   type: :string,
                   foreign_key: { to_table: :clients, primary_key: :client_id }

      t.string :reqid, null: false, unique: true
      t.string :query
      t.string :scope, array: true, default: []
      t.string :redirect_uri, null: false

      t.index :reqid, unique: true

      t.timestamps
    end
  end
end
