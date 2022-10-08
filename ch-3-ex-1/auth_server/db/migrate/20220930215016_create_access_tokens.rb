# frozen_string_literal: true

class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.string :token, null: false, unique: true
      t.string :client_id, null: false
      t.string :scope

      t.index :token, unique: true

      t.timestamps
    end
  end
end
