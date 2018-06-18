class AddAncestryToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :ancestry, :string
    add_index :employees, :ancestry
  end
end
