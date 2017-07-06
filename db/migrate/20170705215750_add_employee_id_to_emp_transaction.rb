class AddEmployeeIdToEmpTransaction < ActiveRecord::Migration
  def up
    add_reference :emp_transactions, :employee, foreign_key: { on_delete: :cascade }
    change_column_null :emp_sec_profiles, :employee_id, false
    change_column_null :emp_sec_profiles, :security_profile_id, false

    Employee.all.each do |employee|
      transactions = []

      OnboardingInfo.where(employee_id: employee.id).each do |o|
        if o.emp_transaction.present?
          transactions << o.emp_transaction.id
        end
      end

      OffboardingInfo.where(employee_id: employee.id).each do |o|
        if o.emp_transaction.present?
          transactions << o.emp_transaction.id
        end
      end

      EmpSecProfile.where(employee_id: employee.id).each do |o|
        if o.emp_transaction.present?
          transactions << o.emp_transaction.id
        end
      end

      transactions.each do |t|
        e = EmpTransaction.find t
        e.employee_id = employee.id
        e.save!
      end
    end

  end

  def down
    remove_reference :emp_transactions, :employee
    change_column_null :emp_sec_profiles, :employee_id, true
    change_column_null :emp_sec_profiles, :security_profile_id, true
  end
end
