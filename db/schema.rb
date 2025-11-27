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

ActiveRecord::Schema[8.1].define(version: 2025_11_23_220637) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "uuid-ossp"

  create_table "account_memberships", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "public_id", default: -> { "gen_uuidv7()" }, null: false
    t.integer "role", default: 0
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_account_memberships_on_account_id"
    t.index ["public_id"], name: "index_account_memberships_on_public_id", unique: true
    t.index ["user_id", "account_id"], name: "index_account_memberships_on_user_id_and_account_id", unique: true
    t.index ["user_id"], name: "index_account_memberships_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "plan", default: 0
    t.uuid "public_id", default: -> { "gen_uuidv7()" }, null: false
    t.string "slug", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["public_id"], name: "index_accounts_on_public_id", unique: true
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "device_info", default: {}
    t.datetime "expires_at", null: false
    t.string "jti", null: false
    t.datetime "last_used_at"
    t.uuid "public_id", default: -> { "gen_uuidv7()" }, null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["jti"], name: "index_refresh_tokens_on_jti", unique: true
    t.index ["public_id"], name: "index_refresh_tokens_on_public_id", unique: true
    t.index ["user_id", "revoked_at"], name: "index_refresh_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.uuid "public_id", default: -> { "gen_uuidv7()" }, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
  end

  add_foreign_key "account_memberships", "accounts"
  add_foreign_key "account_memberships", "users"
  add_foreign_key "refresh_tokens", "users"
end
