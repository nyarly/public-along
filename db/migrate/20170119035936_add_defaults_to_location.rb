class AddDefaultsToLocation < ActiveRecord::Migration
  def change
    change_column :locations, :country, :string, :default => "Pending Assignment"
    change_column :locations, :kind, :string, :default => "Pending Assignment"
    change_column :locations, :timezone, :string, :default => "Pending Assignment"
  end
end
