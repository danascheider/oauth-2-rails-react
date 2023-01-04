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

ActiveRecord::Schema[7.0].define(version: 2023_01_04_174237) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.json "query"
    t.string "scope", default: [], null: false, array: true
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_requests_on_client_id"
    t.index ["reqid"], name: "index_requests_on_reqid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "sub", null: false
    t.string "preferred_username"
    t.string "name"
    t.string "email"
    t.boolean "email_verified", default: false
    t.string "username"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["sub"], name: "index_users_on_sub", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "requests", "clients", primary_key: "client_id"
end
