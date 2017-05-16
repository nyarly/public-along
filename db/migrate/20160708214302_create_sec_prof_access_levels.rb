class CreateSecProfAccessLevels < ActiveRecord::Migration
  def change
    create_table :sec_prof_access_levels do |t|
      t.integer :access_level_id
      t.integer :security_profile_id

      t.timestamps null: false
    end
  end
end
