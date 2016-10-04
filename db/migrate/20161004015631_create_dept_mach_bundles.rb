class CreateDeptMachBundles < ActiveRecord::Migration
  def change
    create_table :dept_mach_bundles do |t|
      t.integer :department_id
      t.integer :machine_bundle_id

      t.timestamps null: false
    end
  end
end
