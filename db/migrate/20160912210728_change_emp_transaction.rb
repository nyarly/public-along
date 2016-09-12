class ChangeEmpTransaction < ActiveRecord::Migration
  def change
    remove_column :emp_transactions, :buddy_id, :integer
    remove_column :emp_transactions, :cw_email, :boolean
    remove_column :emp_transactions, :cw_google_membership, :boolean
  end
end
