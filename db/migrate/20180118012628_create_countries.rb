class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso_alpha_2_code
      t.references :currency, index: true

      t.timestamps
    end
  end
end
