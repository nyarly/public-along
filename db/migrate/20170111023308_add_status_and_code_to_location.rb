class AddStatusAndCodeToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :status, :string
    add_column :locations, :code, :string
  end
end
