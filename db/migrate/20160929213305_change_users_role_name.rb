class ChangeUsersRoleName < ActiveRecord::Migration
  def change
    rename_column :users, :role_name, :role_names
  end
end
