class AddLeaveDatesToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :leave_start_date, :datetime
    add_column :employees, :leave_return_date, :datetime
  end
end
