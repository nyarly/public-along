class CreateAdpEvents < ActiveRecord::Migration
  def change
    create_table :adp_events do |t|
      t.text :json
      t.text :msg_id
      t.text :status

      t.timestamps null: false
    end
  end
end
