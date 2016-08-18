class CreateEmpSecProfiles < ActiveRecord::Migration
  def change
    create_table :emp_sec_profiles do |t|
      t.integer :transaction_id
      t.integer :employee_id
      t.integer :security_profile_id
      t.datetime :revoke_date

      t.timestamps null: false
    end
  end
end
