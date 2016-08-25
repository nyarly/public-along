class AddContingentWorkerInfoToEmpTransaction < ActiveRecord::Migration
  def change
    add_column :emp_transactions, :cw_email, :boolean
    add_column :emp_transactions, :cw_google_membership, :boolean
  end
end
