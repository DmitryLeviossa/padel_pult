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

ActiveRecord::Schema[8.0].define(version: 2026_05_08_133808) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "league_users", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "user_id", null: false
    t.integer "score", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_league_users_on_league_id"
    t.index ["user_id"], name: "index_league_users_on_user_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_leagues_on_owner_id"
  end

  create_table "pairs", force: :cascade do |t|
    t.bigint "player1_id", null: false
    t.bigint "player2_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player1_id"], name: "index_pairs_on_player1_id"
    t.index ["player2_id"], name: "index_pairs_on_player2_id"
    t.index ["tournament_id"], name: "index_pairs_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "max_participants", default: 16, null: false
    t.string "location"
    t.string "type", default: "olimpic", null: false
    t.string "status", default: "draft", null: false
    t.text "description"
    t.bigint "league_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_tournaments_on_league_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "league_users", "leagues"
  add_foreign_key "league_users", "users"
  add_foreign_key "leagues", "users", column: "owner_id"
  add_foreign_key "pairs", "tournaments"
  add_foreign_key "pairs", "users", column: "player1_id"
  add_foreign_key "pairs", "users", column: "player2_id"
  add_foreign_key "tournaments", "leagues"
end
