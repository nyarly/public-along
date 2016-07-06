class ChangeEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :department_id, :integer
    remove_column :employees, :cost_center, :string
    remove_column :employees, :cost_center_id, :string
  end
end
