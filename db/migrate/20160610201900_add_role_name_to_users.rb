class AddRoleNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :role_name, :string, null: false, default: "Basic"
  end
end
