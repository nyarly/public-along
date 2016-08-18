class RenameTransIdEmpSecProfile < ActiveRecord::Migration
  def change
    remove_column :emp_sec_profiles, :transaction_id, :integer
    add_column :emp_sec_profiles, :emp_transaction_id, :integer
  end
end
