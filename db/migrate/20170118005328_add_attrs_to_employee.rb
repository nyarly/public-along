class AddAttrsToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :company, :string
    add_column :employees, :status, :string
  end
end
