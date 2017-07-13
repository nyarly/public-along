class EmpSecProfile < ActiveRecord::Base

  validates :security_profile_id,
            presence: true
  validate :cannot_have_dup_active_security_profiles

  belongs_to :emp_transaction
  belongs_to :security_profile
  belongs_to :revoking_transaction, class_name: "EmpTransaction", inverse_of: :revoked_emp_sec_profiles

  def cannot_have_dup_active_security_profiles
    unless security_profile_id.blank?

      if defined? employee_id && employee_id.present?
        employee_id = employee_id
      elsif emp_transaction_id.present?
        emp = EmpTransaction.find_by_id(emp_transaction_id)
        employee_id = emp.employee_id
      end

      if employee_id.present?
        employee = Employee.find_by_id(employee_id)
        active_emp_sec_profiles = employee.emp_sec_profiles.where("security_profile_id = ? AND revoking_transaction_id IS NULL", security_profile_id)

        if self.persisted?
          active_emp_sec_profiles = active_emp_sec_profiles.where("emp_sec_profiles.id != ?", id)
        end

        active_emp_sec_profiles = active_emp_sec_profiles.limit(1)

        unless active_emp_sec_profiles.count == 0
          errors.add(:security_profile_id, "can't have duplicate security profiles for one employee")
        end
      end
    end
  end
end
