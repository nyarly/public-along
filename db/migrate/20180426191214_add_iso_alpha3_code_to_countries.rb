class AddIsoAlpha3CodeToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :iso_alpha_3, :string
    rename_column :countries, :iso_alpha_2_code, :iso_alpha_2
  end
end
