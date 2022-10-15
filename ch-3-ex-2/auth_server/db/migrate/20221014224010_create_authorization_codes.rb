# frozen_string_literal: true

class CreateAuthorizationCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_codes do |t|
      t.string :code, null: false, unique: true
      t.json :authorization_endpoint_request
      t.string :scope, array: true, null: false, default: []

      t.index :code, unique: true

      t.timestamps
    end
  end
end
