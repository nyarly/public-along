class CreateAccessLevels < ActiveRecord::Migration
  def change
    create_table :access_levels do |t|
      t.string :name
      t.integer :application_id

      t.timestamps null: false
    end
  end
end
