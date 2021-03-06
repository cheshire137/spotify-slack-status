# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170415163133) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "slack_tokens", force: :cascade do |t|
    t.integer  "user_id",       null: false
    t.string   "token",         null: false
    t.string   "team_id",       null: false
    t.string   "team_name",     null: false
    t.string   "slack_user_id", null: false
    t.string   "user_name",     null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["user_id", "team_id", "slack_user_id"], name: "index_slack_tokens_on_user_id_and_team_id_and_slack_user_id", unique: true, using: :btree
    t.index ["user_id"], name: "index_slack_tokens_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                 null: false
    t.string   "user_name",             null: false
    t.string   "spotify_access_token"
    t.string   "spotify_refresh_token"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["user_name"], name: "index_users_on_user_name", using: :btree
  end

end
