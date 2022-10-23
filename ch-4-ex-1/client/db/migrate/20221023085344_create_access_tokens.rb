# frozen_string_literal: true

class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.string :access_token, unique: true, null: false
      t.string :refresh_token
      t.string :token_type, null: false
      t.string :scope, array: true, null: false, default: []

      t.index :access_token, unique: true

      t.timestamps
    end
  end
end
