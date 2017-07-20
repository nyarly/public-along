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

ActiveRecord::Schema.define(version: 20170714203809) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "access_levels", force: :cascade do |t|
    t.string   "name",              null: false
    t.integer  "application_id",    null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "ad_security_group"
  end

  create_table "adp_events", force: :cascade do |t|
    t.text     "json"
    t.text     "msg_id"
    t.text     "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "applications", force: :cascade do |t|
    t.string   "name",                                  null: false
    t.text     "description"
    t.text     "dependency"
    t.text     "onboard_instructions"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.text     "offboard_instructions"
    t.boolean  "ad_controls",           default: false, null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string   "name",          null: false
    t.string   "code",          null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "parent_org_id"
    t.string   "status"
  end

  create_table "dept_mach_bundles", force: :cascade do |t|
    t.integer  "department_id",     null: false
    t.integer  "machine_bundle_id", null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "dept_sec_profs", force: :cascade do |t|
    t.integer  "department_id",       null: false
    t.integer  "security_profile_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "emp_access_levels", force: :cascade do |t|
    t.integer  "access_level_id",                null: false
    t.boolean  "active",          default: true, null: false
    t.integer  "employee_id",                    null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "emp_access_levels", ["access_level_id"], name: "index_emp_access_levels_on_access_level_id", using: :btree
  add_index "emp_access_levels", ["employee_id"], name: "index_emp_access_levels_on_employee_id", using: :btree

  create_table "emp_delta", force: :cascade do |t|
    t.integer  "employee_id", null: false
    t.hstore   "before"
    t.hstore   "after"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "emp_mach_bundles", force: :cascade do |t|
    t.integer  "machine_bundle_id",  null: false
    t.integer  "emp_transaction_id", null: false
    t.hstore   "details"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "emp_sec_profiles", force: :cascade do |t|
    t.integer  "security_profile_id",     null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "emp_transaction_id"
    t.integer  "revoking_transaction_id"
  end

  create_table "emp_transactions", force: :cascade do |t|
    t.string   "kind",        null: false
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "notes"
    t.integer  "employee_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string   "email"
    t.string   "first_name",             null: false
    t.string   "last_name",              null: false
    t.string   "workday_username"
    t.string   "employee_id",            null: false
    t.datetime "hire_date",              null: false
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
    t.integer  "department_id",          null: false
    t.integer  "location_id",            null: false
    t.string   "sam_account_name"
    t.string   "company"
    t.string   "status"
    t.string   "adp_assoc_oid"
    t.integer  "worker_type_id",         null: false
    t.integer  "job_title_id",           null: false
  end

  add_index "employees", ["email"], name: "index_employees_on_email", unique: true, using: :btree
  add_index "employees", ["employee_id"], name: "index_employees_on_employee_id", unique: true, using: :btree

  create_table "job_titles", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "code",       null: false
    t.string   "status",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string   "name",                                      null: false
    t.string   "kind",       default: "Pending Assignment"
    t.string   "country",    default: "Pending Assignment"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "status",                                    null: false
    t.string   "code",                                      null: false
    t.string   "timezone",   default: "Pending Assignment"
  end

  create_table "machine_bundles", force: :cascade do |t|
    t.string   "name",        null: false
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "offboarding_infos", force: :cascade do |t|
    t.integer  "emp_transaction_id",                      null: false
    t.boolean  "archive_data",            default: false, null: false
    t.boolean  "replacement_hired",       default: false, null: false
    t.integer  "forward_email_id"
    t.integer  "reassign_salesforce_id"
    t.integer  "transfer_google_docs_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "onboarding_infos", force: :cascade do |t|
    t.integer  "emp_transaction_id",                   null: false
    t.integer  "buddy_id"
    t.boolean  "cw_email",             default: false, null: false
    t.boolean  "cw_google_membership", default: false, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "parent_orgs", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "code",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sec_prof_access_levels", force: :cascade do |t|
    t.integer  "security_profile_id", null: false
    t.integer  "access_level_id",     null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "security_profiles", force: :cascade do |t|
    t.string   "name",        null: false
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

  create_table "worker_types", force: :cascade do |t|
    t.string   "name",                                      null: false
    t.string   "code",                                      null: false
    t.string   "kind",       default: "Pending Assignment", null: false
    t.string   "status"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "xml_transactions", force: :cascade do |t|
    t.string   "name"
    t.string   "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "access_levels", "applications", on_delete: :cascade
  add_foreign_key "departments", "parent_orgs", on_delete: :cascade
  add_foreign_key "dept_mach_bundles", "departments", on_delete: :cascade
  add_foreign_key "dept_mach_bundles", "machine_bundles", on_delete: :cascade
  add_foreign_key "dept_sec_profs", "departments", on_delete: :cascade
  add_foreign_key "dept_sec_profs", "security_profiles", on_delete: :cascade
  add_foreign_key "emp_access_levels", "access_levels", on_delete: :cascade
  add_foreign_key "emp_access_levels", "employees", on_delete: :cascade
  add_foreign_key "emp_delta", "employees", on_delete: :cascade
  add_foreign_key "emp_mach_bundles", "emp_transactions", on_delete: :cascade
  add_foreign_key "emp_mach_bundles", "machine_bundles", on_delete: :cascade
  add_foreign_key "emp_sec_profiles", "emp_transactions", column: "revoking_transaction_id", on_delete: :nullify
  add_foreign_key "emp_sec_profiles", "emp_transactions", on_delete: :nullify
  add_foreign_key "emp_sec_profiles", "security_profiles", on_delete: :cascade
  add_foreign_key "emp_transactions", "employees", on_delete: :cascade
  add_foreign_key "emp_transactions", "users", on_delete: :nullify
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
  add_foreign_key "employees", "locations"
  add_foreign_key "employees", "worker_types"
  add_foreign_key "offboarding_infos", "emp_transactions", on_delete: :cascade
  add_foreign_key "offboarding_infos", "employees", column: "forward_email_id", on_delete: :nullify
  add_foreign_key "offboarding_infos", "employees", column: "reassign_salesforce_id", on_delete: :nullify
  add_foreign_key "offboarding_infos", "employees", column: "transfer_google_docs_id", on_delete: :nullify
  add_foreign_key "onboarding_infos", "emp_transactions", on_delete: :cascade
  add_foreign_key "onboarding_infos", "employees", column: "buddy_id", on_delete: :nullify
  add_foreign_key "sec_prof_access_levels", "access_levels", on_delete: :cascade
  add_foreign_key "sec_prof_access_levels", "security_profiles", on_delete: :cascade
end
