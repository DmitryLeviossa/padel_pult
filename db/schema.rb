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

ActiveRecord::Schema[8.0].define(version: 2026_05_18_205600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "league_invitations", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "invited_user_id", null: false
    t.bigint "invited_by_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_league_invitations_on_invited_by_id"
    t.index ["invited_user_id"], name: "index_league_invitations_on_invited_user_id"
    t.index ["league_id", "invited_user_id"], name: "index_league_invitations_on_league_id_and_invited_user_id", unique: true
    t.index ["league_id"], name: "index_league_invitations_on_league_id"
  end

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

  create_table "matches", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.bigint "pair1_id"
    t.bigint "pair2_id"
    t.bigint "winner_id"
    t.integer "pair1_score"
    t.integer "pair2_score"
    t.integer "round_number", null: false
    t.integer "position", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pair1_id"], name: "index_matches_on_pair1_id"
    t.index ["pair2_id"], name: "index_matches_on_pair2_id"
    t.index ["tournament_id", "round_number", "position"], name: "index_matches_on_tournament_id_and_round_number_and_position", unique: true
    t.index ["tournament_id"], name: "index_matches_on_tournament_id"
    t.index ["winner_id"], name: "index_matches_on_winner_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notification_type", null: false
    t.string "message", null: false
    t.string "url"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pairs", force: :cascade do |t|
    t.bigint "player1_id", null: false
    t.bigint "player2_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "placement"
    t.integer "player1_score", default: 0, null: false
    t.integer "player2_score", default: 0, null: false
    t.index ["player1_id"], name: "index_pairs_on_player1_id"
    t.index ["player2_id"], name: "index_pairs_on_player2_id"
    t.index ["tournament_id"], name: "index_pairs_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.integer "max_participants", default: 16, null: false
    t.string "location"
    t.string "type", default: "olympic", null: false
    t.string "status", default: "draft", null: false
    t.text "description"
    t.bigint "league_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "placement_points", default: [], null: false
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
    t.string "first_name"
    t.string "last_name"
    t.integer "gender"
    t.string "invitation_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "league_invitations", "leagues"
  add_foreign_key "league_invitations", "users", column: "invited_by_id"
  add_foreign_key "league_invitations", "users", column: "invited_user_id"
  add_foreign_key "league_users", "leagues"
  add_foreign_key "league_users", "users"
  add_foreign_key "leagues", "users", column: "owner_id"
  add_foreign_key "matches", "pairs", column: "pair1_id"
  add_foreign_key "matches", "pairs", column: "pair2_id"
  add_foreign_key "matches", "pairs", column: "winner_id"
  add_foreign_key "matches", "tournaments"
  add_foreign_key "notifications", "users"
  add_foreign_key "pairs", "league_users", column: "player1_id"
  add_foreign_key "pairs", "league_users", column: "player2_id"
  add_foreign_key "pairs", "tournaments"
  add_foreign_key "tournaments", "leagues"
end
