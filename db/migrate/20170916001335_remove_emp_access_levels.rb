class RemoveEmpAccessLevels < ActiveRecord::Migration
  def change
    drop_table :emp_access_levels
  end
end
