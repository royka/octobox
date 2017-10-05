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

ActiveRecord::Schema.define(version: 20171005133259) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "github_id"
    t.integer "repository_id"
    t.string "repository_full_name"
    t.string "subject_title"
    t.string "subject_url"
    t.string "subject_type"
    t.string "reason"
    t.boolean "unread"
    t.datetime "updated_at", null: false
    t.string "last_read_at"
    t.string "url"
    t.boolean "archived", default: false
    t.datetime "created_at", null: false
    t.boolean "starred", default: false
    t.string "repository_owner_name", default: ""
    t.string "latest_comment_url"
    t.index "to_tsvector('english'::regconfig, (subject_title)::text)", name: "notifications_subject_title", using: :gin
    t.index ["user_id", "archived", "updated_at"], name: "index_notifications_on_user_id_and_archived_and_updated_at"
    t.index ["user_id", "github_id"], name: "index_notifications_on_user_id_and_github_id", unique: true
  end

  create_table "subjects", force: :cascade do |t|
    t.string "url"
    t.string "state"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "html_url"
    t.index ["url"], name: "index_subjects_on_url"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "github_id", null: false
    t.string "access_token", null: false
    t.string "github_login", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.string "personal_access_token"
    t.integer "refresh_interval", default: 0
    t.string "api_key"
    t.index ["access_token"], name: "index_users_on_access_token", unique: true
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
  end

end
