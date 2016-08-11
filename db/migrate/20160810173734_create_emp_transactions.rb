class CreateEmpTransactions < ActiveRecord::Migration
  def change
    create_table :emp_transactions do |t|
      t.string :kind
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
