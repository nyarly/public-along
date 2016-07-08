class CreateApplications < ActiveRecord::Migration
  def change
    create_table :applications do |t|
      t.string :name
      t.text :description
      t.string :ad_security_group
      t.text :dependency
      t.text :instructions

      t.timestamps null: false
    end
  end
end
