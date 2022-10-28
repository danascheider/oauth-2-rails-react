# frozen_string_literal: true

class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.references :client,
                   null: false,
                   type: :string,
                   foreign_key: { to_table: :clients, primary_key: :client_id }

      t.references :user, null: false, foreign_key: true
      t.string :token, null: false, unique: true
      t.string :token_type, null: false
      t.string :scope, array: true, null: false, default: []

      t.index :token, unique: true

      t.timestamps
    end
  end
end
