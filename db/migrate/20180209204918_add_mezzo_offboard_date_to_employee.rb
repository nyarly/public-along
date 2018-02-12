class AddMezzoOffboardDateToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :offboarded_at, :datetime
  end
end
