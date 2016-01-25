# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160104185523) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "assignments", force: :cascade do |t|
    t.uuid     "assignment_id"
    t.uuid     "person_id"
    t.uuid     "ministry_id"
    t.string   "team_role"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "ministries", force: :cascade do |t|
    t.uuid     "ministry_id"
    t.string   "name"
    t.string   "min_code"
    t.float    "lat"
    t.float    "long"
    t.integer  "zoom"
    t.string   "lmi_show",                                          array: true
    t.string   "lmi_hide",                                          array: true
    t.boolean  "slm"
    t.boolean  "llm"
    t.boolean  "gcm"
    t.boolean  "ds"
    t.string   "default_mcc"
    t.uuid     "parent_ministry_id"
    t.datetime "created_at",         default: "now()", null: false
    t.datetime "updated_at",         default: "now()", null: false
  end

  add_index "ministries", ["ministry_id"], name: "index_ministries_on_ministry_id", unique: true, using: :btree

  create_table "people", force: :cascade do |t|
    t.uuid     "person_id"
    t.string   "first_name"
    t.string   "last_name"
    t.uuid     "cas_guid"
    t.string   "cas_username"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "user_content_locales", force: :cascade do |t|
    t.uuid     "person_id"
    t.uuid     "ministry_id"
    t.string   "locale"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_content_locales", ["person_id", "ministry_id"], name: "index_user_content_locales_on_person_id_and_ministry_id", unique: true, using: :btree

  create_table "user_map_views", force: :cascade do |t|
    t.uuid     "person_id"
    t.uuid     "ministry_id"
    t.float    "lat"
    t.float    "long"
    t.integer  "zoom"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_map_views", ["person_id", "ministry_id"], name: "index_user_map_views_on_person_id_and_ministry_id", unique: true, using: :btree

  create_table "user_measurement_states", force: :cascade do |t|
    t.uuid     "person_id"
    t.string   "mcc"
    t.string   "perm_link_stub"
    t.boolean  "visible"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "user_measurement_states", ["person_id", "mcc", "perm_link_stub"], name: "unique_index_user_measurement_states", unique: true, using: :btree

  create_table "user_preferences", force: :cascade do |t|
    t.uuid     "person_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_preferences", ["person_id", "name"], name: "index_user_preferences_on_person_id_and_name", unique: true, using: :btree

end
