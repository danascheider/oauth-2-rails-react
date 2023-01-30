# frozen_string_literal: true

class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.references :user, foreign_key: true
      t.references :client,
                   null: false,
                   type: :string,
                   foreign_key: { to_table: :clients, primary_key: :client_id }

      t.string :token, null: false
      t.string :token_type, null: false, default: 'Bearer'
      t.string :scope, array: true, null: false, default: []
      t.datetime :expires_at, null: false

      t.index :token, unique: true

      t.timestamps
    end
  end
end
