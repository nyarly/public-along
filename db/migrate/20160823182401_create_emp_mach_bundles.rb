class CreateEmpMachBundles < ActiveRecord::Migration
  def change
    enable_extension 'hstore' unless extension_enabled?('hstore')
    create_table :emp_mach_bundles do |t|
      t.integer :employee_id
      t.integer :machine_bundle_id
      t.integer :emp_transaction_id
      t.hstore :details

      t.timestamps null: false
    end
  end
end
