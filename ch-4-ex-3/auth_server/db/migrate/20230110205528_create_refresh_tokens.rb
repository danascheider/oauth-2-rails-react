# frozen_string_literal: true

class CreateRefreshTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, foreign_key: true
      t.references :client,
                   null: false,
                   type: :string,
                   foreign_key: { to_table: :clients, primary_key: :client_id }

      t.string :token, null: false
      t.string :scope, array: true, null: false, default: []

      t.index :token, unique: true
      t.index %i[user_id client_id], unique: true

      t.timestamps
    end
  end
end
