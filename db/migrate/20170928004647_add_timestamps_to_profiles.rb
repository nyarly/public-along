class AddTimestampsToProfiles < ActiveRecord::Migration
  def up
    add_timestamps :profiles, null: true
    Profile.update_all(created_at: Time.zone.now, updated_at: Time.zone.now)
    change_column_null :profiles, :created_at, false
    change_column_null :profiles, :updated_at, false
  end

  def down
    remove_timestamps :profiles
  end
end
