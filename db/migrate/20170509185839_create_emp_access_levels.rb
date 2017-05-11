class CreateEmpAccessLevels < ActiveRecord::Migration
  def change
    create_table :emp_access_levels do |t|
      t.references :access_level, index: true
      t.boolean :active
      t.references :employee, index: true

      t.timestamps null: false
    end

    add_foreign_key :emp_access_levels, :access_levels
    add_foreign_key :emp_access_levels, :employees
  end
end
