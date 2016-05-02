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

ActiveRecord::Schema.define(version: 20160502172653) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "areas", force: :cascade do |t|
    t.uuid     "gr_id"
    t.string   "code"
    t.string   "name"
    t.boolean  "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "assignments", force: :cascade do |t|
    t.uuid     "gr_id"
    t.integer  "person_id",               null: false
    t.integer  "ministry_id",             null: false
    t.integer  "role",        default: 2
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "assignments", ["person_id", "ministry_id"], name: "index_assignments_on_person_id_and_ministry_id", unique: true, using: :btree

  create_table "audits", force: :cascade do |t|
    t.integer  "person_id",     null: false
    t.integer  "ministry_id",   null: false
    t.string   "message",       null: false
    t.integer  "audit_type",    null: false
    t.string   "ministry_name"
    t.datetime "created_at"
  end

  create_table "church_values", force: :cascade do |t|
    t.integer "church_id"
    t.integer "size"
    t.integer "development"
    t.string  "period"
  end

  add_index "church_values", ["church_id", "period"], name: "index_church_values_on_church_id_and_period", unique: true, using: :btree

  create_table "churches", force: :cascade do |t|
    t.string   "name"
    t.float    "longitude"
    t.float    "latitude"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "jf_contrib"
    t.integer  "parent_id"
    t.string   "contact_name"
    t.string   "contact_email"
    t.string   "contact_mobile"
    t.integer  "generation"
    t.integer  "development"
    t.integer  "size"
    t.integer  "security"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.uuid     "gr_id"
    t.integer  "ministry_id"
    t.integer  "created_by_id"
    t.integer  "vc_id"
    t.integer  "children_count", default: 0, null: false
  end

  add_index "churches", ["gr_id"], name: "index_churches_on_gr_id", unique: true, using: :btree
  add_index "churches", ["parent_id"], name: "index_churches_on_parent_id", using: :btree

  create_table "measurement_translations", force: :cascade do |t|
    t.integer  "measurement_id"
    t.string   "language"
    t.string   "name"
    t.string   "description"
    t.integer  "ministry_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "measurement_translations", ["measurement_id"], name: "index_measurement_translations_on_measurement_id", using: :btree
  add_index "measurement_translations", ["ministry_id"], name: "index_measurement_translations_on_ministry_id", using: :btree

  create_table "measurements", force: :cascade do |t|
    t.string   "perm_link"
    t.string   "english"
    t.string   "description"
    t.string   "section"
    t.string   "column"
    t.integer  "sort_order"
    t.uuid     "total_id"
    t.uuid     "local_id"
    t.uuid     "person_id"
    t.boolean  "stage"
    t.integer  "parent_id"
    t.boolean  "leader_only"
    t.boolean  "supported_staff_only"
    t.string   "mcc_filter"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "ministries", force: :cascade do |t|
    t.uuid     "gr_id"
    t.string   "name"
    t.string   "min_code"
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
    t.uuid     "parent_gr_id"
    t.integer  "parent_id"
    t.integer  "lft",                           null: false
    t.integer  "rgt",                           null: false
    t.integer  "depth",            default: 0,  null: false
    t.integer  "area_id"
  end

  add_index "ministries", ["gr_id"], name: "index_ministries_on_gr_id", unique: true, using: :btree
  add_index "ministries", ["min_code"], name: "index_ministries_on_min_code", unique: true, using: :btree

  create_table "people", force: :cascade do |t|
    t.uuid     "gr_id"
    t.string   "first_name"
    t.string   "last_name"
    t.uuid     "cas_guid"
    t.string   "cas_username"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "ea_guid"
    t.string   "email"
    t.string   "preferred_name"
  end

  create_table "stories", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.string   "image"
    t.string   "mcc",            limit: 3
    t.integer  "church_id"
    t.integer  "training_id"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.string   "language"
    t.string   "video_url"
    t.integer  "state",                    default: 0
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "privacy",                  default: 0
    t.integer  "created_by_id"
    t.integer  "ministry_id"
    t.string   "user_image_url"
  end

  add_index "stories", ["church_id"], name: "index_stories_on_church_id", using: :btree
  add_index "stories", ["created_by_id"], name: "index_stories_on_created_by_id", using: :btree
  add_index "stories", ["ministry_id"], name: "index_stories_on_ministry_id", using: :btree
  add_index "stories", ["training_id"], name: "index_stories_on_training_id", using: :btree

  create_table "training_completions", force: :cascade do |t|
    t.integer  "phase"
    t.integer  "number_completed"
    t.datetime "date"
    t.integer  "training_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "training_completions", ["training_id"], name: "index_training_completions_on_training_id", using: :btree

  create_table "trainings", force: :cascade do |t|
    t.integer  "ministry_id"
    t.string   "name"
    t.datetime "date"
    t.string   "type",          limit: 50
    t.string   "mcc",           limit: 3
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.integer  "created_by_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "trainings", ["created_by_id"], name: "index_trainings_on_created_by_id", using: :btree
  add_index "trainings", ["ministry_id"], name: "index_trainings_on_ministry_id", using: :btree

  create_table "user_content_locales", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "ministry_id"
    t.string   "locale"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_content_locales", ["person_id", "ministry_id"], name: "index_user_content_locales_on_person_id_and_ministry_id", unique: true, using: :btree

  create_table "user_map_views", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "ministry_id"
    t.float    "lat"
    t.float    "long"
    t.integer  "zoom"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_map_views", ["person_id", "ministry_id"], name: "index_user_map_views_on_person_id_and_ministry_id", unique: true, using: :btree

  create_table "user_measurement_states", force: :cascade do |t|
    t.integer  "person_id"
    t.string   "mcc"
    t.string   "perm_link_stub"
    t.boolean  "visible"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "user_measurement_states", ["person_id", "mcc", "perm_link_stub"], name: "unique_index_user_measurement_states", unique: true, using: :btree

  create_table "user_preferences", force: :cascade do |t|
    t.integer  "person_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_preferences", ["person_id", "name"], name: "index_user_preferences_on_person_id_and_name", unique: true, using: :btree

  add_foreign_key "assignments", "ministries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "assignments", "people", on_update: :cascade, on_delete: :cascade
  add_foreign_key "audits", "ministries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "audits", "people", on_update: :cascade, on_delete: :cascade
  add_foreign_key "church_values", "churches", on_update: :cascade, on_delete: :restrict
  add_foreign_key "churches", "churches", column: "parent_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "churches", "ministries", on_update: :cascade, on_delete: :restrict
  add_foreign_key "churches", "people", column: "created_by_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "measurement_translations", "measurements", on_update: :cascade, on_delete: :cascade
  add_foreign_key "measurement_translations", "ministries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "stories", "churches", on_update: :cascade, on_delete: :nullify
  add_foreign_key "stories", "ministries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "stories", "people", column: "created_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "stories", "trainings", on_update: :cascade, on_delete: :nullify
  add_foreign_key "training_completions", "trainings", on_update: :cascade, on_delete: :restrict
  add_foreign_key "trainings", "ministries", on_update: :cascade, on_delete: :restrict
  add_foreign_key "trainings", "people", column: "created_by_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "user_content_locales", "ministries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_content_locales", "people", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_map_views", "ministries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_map_views", "people", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_measurement_states", "people", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_preferences", "people", on_update: :cascade, on_delete: :cascade
end
