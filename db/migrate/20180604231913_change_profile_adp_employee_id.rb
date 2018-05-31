class ChangeProfileAdpEmployeeId < ActiveRecord::Migration
  def up
    change_column :profiles, :adp_employee_id, :string, null: true
  end

  def down
    change_column :profiles, :adp_employee_id, :string, null: false, default: ''
  end
end
