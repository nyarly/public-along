class RemoveEmployeeFromEmpSecProfile < ActiveRecord::Migration
  def up
    change_column_null :emp_sec_profiles, :employee_id, true

    EmpSecProfile.where(emp_transaction_id: nil).all.each do |e|
      emp = EmpTransaction.new(
        kind: "Service",
        employee_id: e.employee_id,
        notes: "Created in emp sec profile migration",
        emp_sec_profiles: [e]
      )
      emp.save!
    end

    remove_column :emp_sec_profiles, :employee_id
  end

  def down
    add_column :emp_sec_profiles, :employee_id, :integer

    EmpSecProfile.all.each do |esp|
      if esp.emp_transaction.present? && esp.emp_transaction.employee_id.present?
        esp.employee_id = esp.emp_transaction.employee_id

        if esp.emp_transaction.notes == "Created in emp sec profile migration"
          et = EmpTransaction.find(esp.emp_transaction_id)
          et.delete
          esp.emp_transaction_id = nil
        end

        esp.save!
      end
    end

    change_column_null :emp_sec_profiles, :employee_id, false
  end
end
