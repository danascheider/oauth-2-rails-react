# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :sub, null: false
      t.string :preferred_username
      t.string :name
      t.string :email
      t.boolean :email_verified
      t.string :username
      t.string :password

      t.index :sub, unique: true
      t.index :email, unique: true
      t.index :username, unique: true

      t.timestamps
    end
  end
end
