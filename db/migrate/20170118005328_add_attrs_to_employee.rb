class AddAttrsToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :company, :string
    add_column :employees, :status, :string
    add_column :employees, :adp_assoc_oid, :string
  end
end
