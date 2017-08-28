class RenameEmployeeColumns < ActiveRecord::Migration
  def up
    rename_column :employees, :workday_username, :del_workday_username
    rename_column :employees, :job_family_id, :del_job_family_id
    rename_column :employees, :job_family, :del_job_family
    rename_column :employees, :job_profile_id, :del_job_profile_id
    rename_column :employees, :job_profile, :del_job_profile
    rename_column :employees, :employee_type, :del_employee_type
    rename_column :employees, :contingent_worker_id, :del_contingent_worker_id
    rename_column :employees, :contingent_worker_type, :del_contingent_worker_type
    rename_column :employees, :employee_id, :del_employee_id
    rename_column :employees, :business_title, :del_business_title
    rename_column :employees, :manager_id, :del_manager_id
    rename_column :employees, :department_id, :del_department_id
    rename_column :employees, :location_id, :del_location_id
    rename_column :employees, :company, :del_company
    rename_column :employees, :adp_assoc_oid, :del_adp_assoc_oid
    rename_column :employees, :worker_type_id, :del_worker_type_id
    rename_column :employees, :job_title_id, :del_job_title_id

    add_foreign_key :profiles, :employees, on_delete: :cascade
    add_foreign_key :profiles, :departments, on_delete: :restrict
    add_foreign_key :profiles, :locations, on_delete: :restrict
    add_foreign_key :profiles, :worker_types, on_delete: :restrict
    add_foreign_key :profiles, :job_titles, on_delete: :restrict
  end

  def down
    rename_column :employees, :del_workday_username, :workday_username
    rename_column :employees, :del_job_family_id, :job_family_id
    rename_column :employees, :del_job_family, :job_family
    rename_column :employees, :del_job_profile_id, :job_profile_id
    rename_column :employees, :del_job_profile, :job_profile
    rename_column :employees, :del_employee_type, :employee_type
    rename_column :employees, :del_contingent_worker_id, :contingent_worker_id
    rename_column :employees, :del_contingent_worker_type, :contingent_worker_type
    rename_column :employees, :del_employee_id, :employee_id
    rename_column :employees, :del_business_title, :business_title
    rename_column :employees, :del_manager_id, :manager_id
    rename_column :employees, :del_department_id, :department_id
    rename_column :employees, :del_location_id, :location_id
    rename_column :employees, :del_company, :company
    rename_column :employees, :del_adp_assoc_oid, :adp_assoc_oid
    rename_column :employees, :del_worker_type_id, :worker_type_id
    rename_column :employees, :del_job_title_id, :job_title_id

    remove_foreign_key :profiles, :employees
    remove_foreign_key :profiles, :departments
    remove_foreign_key :profiles, :locations
    remove_foreign_key :profiles, :worker_types
    remove_foreign_key :profiles, :job_titles
  end
end
