class AddManagementPositionToProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :management_position, :boolean
  end
end
