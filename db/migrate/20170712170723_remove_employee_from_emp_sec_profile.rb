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

    # if you must roll back this migration, the emp_sec_profile model will have to be updated.
    # replace the cannot_have_dup_active_security_profiles with the code below.
    # restore relationships: employee has many emp_sec_profiles and emp_sec_profile belongs to employee.

    #  def cannot_have_dup_active_security_profiles
    #   unless employee_id.blank? || security_profile_id.blank?
    #     emp = Employee.find_by_id(employee_id)
    #     if emp != nil
    #       active_emp_sec_profiles = emp.emp_sec_profiles.where("security_profile_id = ? AND revoking_transaction_id IS NULL", security_profile_id)

    #       if self.persisted?
    #         active_emp_sec_profiles = active_emp_sec_profiles.where("id != ?", id)
    #       end

    #       active_emp_sec_profiles = active_emp_sec_profiles.limit(1)

    #       unless active_emp_sec_profiles.count == 0
    #         errors.add(:security_profile_id, "can't have duplicate security profiles for one employee")
    #       end
    #     end
    #   end
    # end

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
