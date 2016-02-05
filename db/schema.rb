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

ActiveRecord::Schema.define(version: 20160205192735) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "assignments", force: :cascade do |t|
    t.uuid     "assignment_id"
    t.uuid     "person_id"
    t.uuid     "ministry_id"
    t.integer  "role",          default: 2
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "churches", force: :cascade do |t|
    t.string   "church_id"
    t.string   "name"
    t.float    "long"
    t.float    "lat"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "jf_contrib"
    t.integer  "parent_id"
    t.integer  "target_area"
    t.string   "target_area_id", limit: 36
    t.string   "contact_name"
    t.string   "contact_email"
    t.string   "contact_mobile"
    t.integer  "generation"
    t.integer  "development"
    t.integer  "size"
    t.integer  "security"
    t.string   "created_by",     limit: 36
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "churches", ["parent_id"], name: "index_churches_on_parent_id", using: :btree

  create_table "ministries", force: :cascade do |t|
    t.uuid     "ministry_id"
    t.uuid     "parent_id"
    t.string   "name"
    t.string   "min_code"
    t.string   "area_code"
    t.string   "mccs",             default: [],              array: true
    t.string   "default_mcc"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "location_zoom"
    t.string   "lmi_show",         default: [],              array: true
    t.string   "lmi_hide",         default: [],              array: true
    t.boolean  "hide_reports_tab"
    t.string   "currency_code"
    t.string   "currency_symbol"
    t.string   "ministry_scope"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "ministries", ["min_code"], name: "index_ministries_on_min_code", unique: true, using: :btree
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
