class CreateEmpDelta < ActiveRecord::Migration
  def change
    create_table :emp_delta do |t|
      t.integer :employee_id
      t.hstore :before
      t.hstore :after

      t.timestamps null: false
    end
  end
end
