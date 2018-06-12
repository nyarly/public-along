class AddTreeToEmployees < ActiveRecord::Migration
  def up
    add_column :employees, :lft, :integer, null: false, default: 0, index: true
    add_column :employees, :rgt, :integer, null: false, default: 0, index: true
  end

  def down
    remove_column :employees, :lft
    remove_column :employees, :rgt
  end
end
