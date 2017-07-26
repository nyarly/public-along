class RemoveEmployeeIdFromEmpMachBundle < ActiveRecord::Migration
  def up
    remove_column :emp_mach_bundles, :employee_id
  end

  def down
    add_column :emp_mach_bundles, :employee_id, :integer

    EmpMachBundles.all.each do |e|
      e.employee_id = e.emp_transaction.employee_id
      e.save!
    end

    change_column_null :emp_mach_bundles, :employee_id, false
  end
end
