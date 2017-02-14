class AddStatusToDepartment < ActiveRecord::Migration
  def change
    add_column :departments, :status, :string
  end
end
