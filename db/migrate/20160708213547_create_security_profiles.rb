class CreateSecurityProfiles < ActiveRecord::Migration
  def change
    create_table :security_profiles do |t|
      t.string :name
      t.text :description

      t.timestamps null: false
    end
  end
end
