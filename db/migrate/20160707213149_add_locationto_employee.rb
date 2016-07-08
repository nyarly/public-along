class AddLocationtoEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :location_id, :integer
    remove_column :employees, :location, :string
    remove_column :employees, :location_type, :string
    remove_column :employees, :country, :string
  end
end
