class ChangeEmpSecProfileRevokeDateToRevokingTransaction < ActiveRecord::Migration
  def change
    add_column :emp_sec_profiles, :revoking_transaction_id, :integer
    remove_column :emp_sec_profiles, :revoke_date, :datetime
  end
end
