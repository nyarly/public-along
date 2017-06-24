class AddForeignKeys < ActiveRecord::Migration
  def change
    add_foreign_key :employees, :job_titles, dependent: :restrict
    add_foreign_key :employees, :locations, dependent: :restrict
    add_foreign_key :employees, :worker_types, dependent: :restrict
    add_foreign_key :employees, :departments, dependent: :restrict
    add_foreign_key :emp_sec_profiles, :employees, on_delete: :cascade
    add_foreign_key :offboarding_infos, :employees, on_delete: :cascade
    add_foreign_key :onboarding_infos, :employees, on_delete: :cascade
    add_foreign_key :emp_mach_bundles, :employees, on_delete: :cascade
  end
end
