class AddPrimarytoProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :primary, :boolean, null: false, default: false
  end
end
