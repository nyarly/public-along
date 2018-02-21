class RenameLocationCountry < ActiveRecord::Migration
  def change
    rename_column :locations, :country, :del_country
  end
end
