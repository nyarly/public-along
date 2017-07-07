class AddUniqueConstraintToEmployees < ActiveRecord::Migration
  def change
    add_index :employees, :employee_id, unique: true
    add_index :employees, :email, unique: true
  end
end
