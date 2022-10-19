# frozen_string_literal: true

class CreateRefreshTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :refresh_tokens do |t|
      t.references :client,
                   type: :string,
                   null: false,
                   foreign_key: { to_table: :clients, primary_key: :client_id }

      t.string :token, unique: true
      t.string :scope, null: false, default: ''

      t.index :token, unique: true

      t.timestamps
    end
  end
end
