class CreateBusinessUnits < ActiveRecord::Migration
  def change
    create_table :business_units do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: false

      t.timestamps
    end
  end
end
