class AddAttrsToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :status, :string
    add_column :locations, :code, :string
    add_column :locations, :timezone, :string
  end
end
