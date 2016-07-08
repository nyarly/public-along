class CreateDeptSecProfs < ActiveRecord::Migration
  def change
    create_table :dept_sec_profs do |t|
      t.integer :department_id
      t.integer :security_profile_id

      t.timestamps null: false
    end
  end
end
