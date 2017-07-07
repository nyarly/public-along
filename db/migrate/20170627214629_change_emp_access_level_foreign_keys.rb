class ChangeEmpAccessLevelForeignKeys < ActiveRecord::Migration
  def up
    remove_foreign_key :emp_access_levels, :access_levels
    remove_foreign_key :emp_access_levels, :employees
    add_foreign_key :emp_access_levels, :access_levels, on_delete: :cascade
    add_foreign_key :emp_access_levels, :employees, on_delete: :cascade
  end

  def down
    remove_foreign_key :emp_access_levels, :access_levels
    remove_foreign_key :emp_access_levels, :employees
    add_foreign_key :emp_access_levels, :access_levels
    add_foreign_key :emp_access_levels, :employees
  end
end
