class RemoveNullContraintOnEmpTransaction < ActiveRecord::Migration
  def up
    change_column_null :emp_transactions, :user_id, true
  end

  def down
    change_column_null :emp_transactions, :user_id, false
  end
end
