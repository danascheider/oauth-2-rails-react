# frozen_string_literal: true

class CreateAuthorizationRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_requests do |t|
      t.string :state, null: false
      t.string :response_type, null: false
      t.string :redirect_uri, null: false

      t.index :state, unique: true

      t.timestamps
    end
  end
end
