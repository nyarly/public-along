class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :type
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
