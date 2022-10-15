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

ActiveRecord::Schema[7.0].define(version: 2022_10_14_224010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authorization_codes", force: :cascade do |t|
    t.string "code", null: false
    t.json "authorization_endpoint_request"
    t.string "scope", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_authorization_codes_on_code", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.string "scope", default: [], array: true
    t.string "redirect_uris", null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_clients_on_client_id", unique: true
  end

  create_table "requests", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "reqid", null: false
    t.string "query"
    t.string "scope", default: [], array: true
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_requests_on_client_id"
    t.index ["reqid"], name: "index_requests_on_reqid", unique: true
  end

  add_foreign_key "requests", "clients", primary_key: "client_id"
end
