# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_01_29_190846) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authorization_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "client_id", null: false
    t.string "code", null: false
    t.string "scope", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_authorization_codes_on_client_id"
    t.index ["code"], name: "index_authorization_codes_on_code", unique: true
    t.index ["user_id"], name: "index_authorization_codes_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.string "scope", default: [], null: false, array: true
    t.string "redirect_uris", null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_clients_on_client_id", unique: true
  end

  create_table "requests", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "reqid", null: false
    t.string "state"
    t.string "response_type"
    t.string "scope", default: [], null: false, array: true
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_requests_on_client_id"
    t.index ["reqid"], name: "index_requests_on_reqid", unique: true
    t.index ["state"], name: "index_requests_on_state", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "sub", null: false
    t.string "preferred_username"
    t.string "name", null: false
    t.string "email", null: false
    t.boolean "email_verified"
    t.string "username"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["sub"], name: "index_users_on_sub", unique: true
  end

  add_foreign_key "authorization_codes", "clients", primary_key: "client_id"
  add_foreign_key "authorization_codes", "users"
  add_foreign_key "requests", "clients", primary_key: "client_id"
end
