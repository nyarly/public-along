class AddParentOrgIdToDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :parent_org_id, :integer
  end
end
