class AddForeignKeys < ActiveRecord::Migration
  def change
    add_foreign_key :employees, :job_titles, dependent: :restrict
    add_foreign_key :employees, :locations, dependent: :restrict
    add_foreign_key :employees, :worker_types, dependent: :restrict
    add_foreign_key :employees, :departments, dependent: :restrict
    add_foreign_key :emp_delta, :employees, on_delete: :cascade
    add_foreign_key :emp_sec_profiles, :employees, on_delete: :cascade
    add_foreign_key :emp_sec_profiles, :security_profiles, on_delete: :cascade
    add_foreign_key :emp_sec_profiles, :emp_transactions, on_delete: :nullify
    add_foreign_key :emp_sec_profiles, :emp_transactions, column: :revoking_transaction_id, on_delete: :nullify
    add_foreign_key :offboarding_infos, :employees, on_delete: :cascade
    add_foreign_key :offboarding_infos, :emp_transactions, on_delete: :cascade
    add_foreign_key :offboarding_infos, :employees, column: :forward_email_id, on_delete: :nullify
    add_foreign_key :offboarding_infos, :employees, column: :reassign_salesforce_id, on_delete: :nullify
    add_foreign_key :offboarding_infos, :employees, column: :transfer_google_docs_id, on_delete: :nullify
    add_foreign_key :onboarding_infos, :employees, on_delete: :cascade
    add_foreign_key :onboarding_infos, :emp_transactions, on_delete: :cascade
    add_foreign_key :onboarding_infos, :employees, column: :buddy_id, on_delete: :nullify
    add_foreign_key :emp_mach_bundles, :employees, on_delete: :cascade
    add_foreign_key :emp_mach_bundles, :emp_transactions, on_delete: :cascade
    add_foreign_key :emp_mach_bundles, :machine_bundles, on_delete: :cascade
    add_foreign_key :dept_mach_bundles, :machine_bundles, on_delete: :cascade
    add_foreign_key :dept_mach_bundles, :departments, on_delete: :cascade
    add_foreign_key :departments, :parent_orgs, on_delete: :cascade
    add_foreign_key :dept_sec_profs, :departments, on_delete: :cascade
    add_foreign_key :dept_sec_profs, :security_profiles, on_delete: :cascade
    add_foreign_key :sec_prof_access_levels, :access_levels, on_delete: :cascade
    add_foreign_key :sec_prof_access_levels, :security_profiles, on_delete: :cascade
    add_foreign_key :access_levels, :applications, on_delete: :cascade
    add_foreign_key :emp_transactions, :users, on_delete: :nullify
  end
end
