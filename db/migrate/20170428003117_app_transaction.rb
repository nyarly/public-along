class AppTransaction < ActiveRecord::Migration
  def change
    create_table :app_transactions do |t|
      t.integer :emp_transaction_id
      t.integer :application_id
      t.string :status

      t.timestamps null: false
    end
  end
end
