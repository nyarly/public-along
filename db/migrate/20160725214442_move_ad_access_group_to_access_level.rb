class MoveAdAccessGroupToAccessLevel < ActiveRecord::Migration
  def change
    remove_column :applications, :ad_security_group, :string
    add_column :access_levels, :ad_security_group, :string
  end
end
