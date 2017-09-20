class RemoveEmpAccessLevels < ActiveRecord::Migration
  def change
    drop_table :emp_access_levels do |t|
      t.integer :access_level_id
      t.integer :employee_id
      t.boolean :active
    end
  end
end
