class CreateMachineBundles < ActiveRecord::Migration
  def change
    create_table :machine_bundles do |t|
      t.string :name
      t.text :description

      t.timestamps null: false
    end
  end
end
