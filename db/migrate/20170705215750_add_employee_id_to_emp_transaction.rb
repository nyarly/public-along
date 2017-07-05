class AddEmployeeIdToEmpTransaction < ActiveRecord::Migration
  def change
    add_column :emp_transactions, :employee_id, :integer
    add_foreign_key :emp_transactions, :employees, on_delete: :cascade
  end
end
