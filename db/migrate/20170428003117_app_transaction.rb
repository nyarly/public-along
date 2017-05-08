class AppTransaction < ActiveRecord::Migration
  def change
    create_table :app_transactions do |t|
      t.integer :emp_transaction_id
      t.integer :application_id
      t.string :status

      t.timestamps null: false
    end

    add_foreign_key :app_transactions, :emp_transactions
  end
end
