class AddEmployeeToUser < ActiveRecord::Migration
  def change
    rename_column :users, :employee_id, :adp_employee_id
    add_reference :users, :employee, index: true
  end
end
