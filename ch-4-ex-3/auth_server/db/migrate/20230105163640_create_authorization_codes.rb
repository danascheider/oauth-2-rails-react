# frozen_string_literal: true

class CreateAuthorizationCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :client,
                   null: false,
                   type: :string,
                   foreign_key: { to_table: :clients, primary_key: :client_id }

      t.string :code, null: false
      t.string :scope, array: true, null: false, default: []
      t.json :authorization_endpoint_request

      t.index :code, unique: true

      t.timestamps
    end
  end
end
