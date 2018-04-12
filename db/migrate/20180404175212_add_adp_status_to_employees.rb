class AddAdpStatusToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :adp_status, :string
  end
end
