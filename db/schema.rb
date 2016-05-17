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

ActiveRecord::Schema.define(version: 20160517181703) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "employees", force: :cascade do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "workday_username"
    t.string   "employee_id"
    t.string   "country"
    t.datetime "hire_date"
    t.datetime "contract_end_date"
    t.datetime "termination_date"
    t.string   "job_family_id"
    t.string   "job_family"
    t.string   "job_profile_id"
    t.string   "job_profile"
    t.string   "business_title"
    t.string   "employee_type"
    t.string   "contingent_worker_id"
    t.string   "contingent_worker_type"
    t.string   "location_type"
    t.string   "location"
    t.string   "manager_id"
    t.string   "cost_center"
    t.string   "cost_center_id"
    t.string   "personal_mobile_phone"
    t.string   "office_phone"
    t.string   "home_address_1"
    t.string   "home_address_2"
    t.string   "home_city"
    t.string   "home_state"
    t.string   "home_zip"
    t.string   "image_code"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "ad_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "ldap_user",              default: "", null: false
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["ldap_user"], name: "index_users_on_ldap_user", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
