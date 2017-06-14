class AddAttrsToApplication < ActiveRecord::Migration
  def change
    add_column :applications, :offboard_instructions, :text
    add_column :applications, :ad_controls, :boolean
    rename_column :applications, :instructions, :onboard_instructions
  end
end
