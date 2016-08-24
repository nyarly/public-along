class AddBuddyToEmpTransaction < ActiveRecord::Migration
  def change
    add_column :emp_transactions, :buddy_id, :integer
  end
end
