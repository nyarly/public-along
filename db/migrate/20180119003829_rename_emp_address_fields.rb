class RenameEmpAddressFields < ActiveRecord::Migration
  def change
    rename_column :employees, :home_address_1, :del_home_address_1
    rename_column :employees, :home_address_2, :del_home_address_2
    rename_column :employees, :home_city, :del_home_city
    rename_column :employees, :home_state, :del_home_state
    rename_column :employees, :home_zip, :del_home_zip
  end
end
