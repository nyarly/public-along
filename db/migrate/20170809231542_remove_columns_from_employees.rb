class RemoveColumnsFromEmployees < ActiveRecord::Migration
  def up
    remove_column :employees, :workday_username
    remove_column :employees, :job_family_id
    remove_column :employees, :job_family
    remove_column :employees, :job_profile_id
    remove_column :employees, :job_profile
    remove_column :employees, :employee_type
    remove_column :employees, :contingent_worker_id
    remove_column :employees, :contingent_worker_type
    remove_column :employees, :employee_id
    remove_column :employees, :business_title
    remove_column :employees, :manager_id
    remove_column :employees, :department_id
    remove_column :employees, :location_id
    remove_column :employees, :company
    remove_column :employees, :adp_assoc_oid
    remove_column :employees, :worker_type_id
    remove_column :employees, :job_title_id

    add_foreign_key :profiles, :employees, on_delete: :cascade
    add_foreign_key :profiles, :departments, on_delete: :restrict
    add_foreign_key :profiles, :locations, on_delete: :restrict
    add_foreign_key :profiles, :worker_types, on_delete: :restrict
    add_foreign_key :profiles, :job_titles, on_delete: :restrict
  end

  def down
    add_column :employees, :workday_username, :string
    add_column :employees, :job_family_id, :string
    add_column :employees, :job_family, :string
    add_column :employees, :job_profile_id, :string
    add_column :employees, :job_profile, :string
    add_column :employees, :employee_type, :string
    add_column :employees, :contingent_worker_id, :string
    add_column :employees, :contingent_worker_type, :string
    add_column :employees, :employee_id, :string
    add_column :employees, :business_title, :string
    add_column :employees, :manager_id, :string
    add_column :employees, :department_id, :integer
    add_column :employees, :location_id, :integer
    add_column :employees, :company, :string
    add_column :employees, :adp_assoc_oid, :string
    add_column :employees, :worker_type_id, :integer
    add_column :employees, :job_title_id, :integer

    remove_foreign_key :profiles, :employees
    remove_foreign_key :profiles, :departments
    remove_foreign_key :profiles, :locations
    remove_foreign_key :profiles, :worker_types
    remove_foreign_key :profiles, :job_titles
  end
end
