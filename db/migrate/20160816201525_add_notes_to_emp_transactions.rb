class AddNotesToEmpTransactions < ActiveRecord::Migration
  def change
    add_column :emp_transactions, :notes, :text
  end
end
