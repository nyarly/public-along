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
  end
end
