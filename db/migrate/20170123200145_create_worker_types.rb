class CreateWorkerTypes < ActiveRecord::Migration
  def change
    create_table :worker_types do |t|
      t.string :name
      t.string :code
      t.string :kind, default: "Pending Assignment"
      t.string :status

      t.timestamps null: false
    end
  end
end
