class RemoveNullFromOldCategories < ActiveRecord::Migration
  def up
    change_column_null :employees, :del_employee_id, true
    change_column_null :employees, :del_department_id, true
    change_column_null :employees, :del_location_id, true
    change_column_null :employees, :del_worker_type_id, true
    change_column_null :employees, :del_job_title_id, true
  end

  def down
    change_column_null :employees, :del_employee_id, false
    change_column_null :employees, :del_department_id, false
    change_column_null :employees, :del_location_id, false
    change_column_null :employees, :del_worker_type_id, false
    change_column_null :employees, :del_job_title_id, false
  end
end
