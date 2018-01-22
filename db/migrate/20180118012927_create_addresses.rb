class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :line_1
      t.string :line_2
      t.string :line_3
      t.string :city
      t.string :state_territory
      t.string :postal_code
      t.references :country, index: true
      t.references :addressable, polymorphic: true, index: true, forein_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
