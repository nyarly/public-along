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

ActiveRecord::Schema.define(version: 20161111191909) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "access_levels", force: :cascade do |t|
    t.string   "name"
    t.integer  "application_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "ad_security_group"
  end

  create_table "applications", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.text     "dependency"
    t.text     "instructions"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dept_mach_bundles", force: :cascade do |t|
    t.integer  "department_id"
    t.integer  "machine_bundle_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "dept_sec_profs", force: :cascade do |t|
    t.integer  "department_id"
    t.integer  "security_profile_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "emp_delta", force: :cascade do |t|
    t.integer  "employee_id"
    t.hstore   "before"
    t.hstore   "after"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "emp_mach_bundles", force: :cascade do |t|
    t.integer  "employee_id"
    t.integer  "machine_bundle_id"
    t.integer  "emp_transaction_id"
    t.hstore   "details"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "emp_sec_profiles", force: :cascade do |t|
    t.integer  "employee_id"
    t.integer  "security_profile_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "emp_transaction_id"
    t.integer  "revoking_transaction_id"
  end

  create_table "emp_transactions", force: :cascade do |t|
    t.string   "kind"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "notes"
  end

  create_table "employees", force: :cascade do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "workday_username"
    t.string   "employee_id"
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
    t.string   "manager_id"
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
    t.datetime "leave_start_date"
    t.datetime "leave_return_date"
    t.integer  "department_id"
    t.integer  "location_id"
    t.string   "sam_account_name"
  end

  create_table "locations", force: :cascade do |t|
    t.string   "name"
    t.string   "kind"
    t.string   "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machine_bundles", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "offboarding_infos", force: :cascade do |t|
    t.integer  "employee_id"
    t.integer  "emp_transaction_id"
    t.boolean  "archive_data"
    t.boolean  "replacement_hired"
    t.integer  "forward_email_id"
    t.integer  "reassign_salesforce_id"
    t.integer  "transfer_google_docs_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "onboarding_infos", force: :cascade do |t|
    t.integer  "employee_id"
    t.integer  "emp_transaction_id"
    t.integer  "buddy_id"
    t.boolean  "cw_email"
    t.boolean  "cw_google_membership"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "sec_prof_access_levels", force: :cascade do |t|
    t.integer  "security_profile_id"
    t.integer  "access_level_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "security_profiles", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "ldap_user",              default: "",      null: false
    t.string   "email",                  default: "",      null: false
    t.string   "encrypted_password",     default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,       null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "role_names",             default: "Basic", null: false
    t.string   "employee_id"
  end

  add_index "users", ["ldap_user"], name: "index_users_on_ldap_user", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "xml_transactions", force: :cascade do |t|
    t.string   "name"
    t.string   "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
