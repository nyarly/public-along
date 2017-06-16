class TechTableMailerPreview < ActionMailer::Preview
  def alert_email
    message = "{\n  \"mbros@opentable.com, Mario, \": {\n    \"last_name\": [\n      \"can't be blank\"\n    ]\n  },\n  \", Luddite, Johnson\": {\n    \"Active Directory Error\": \"No email to match to AD records\"\n  },\n  \"nonexistent@opentable.com, Non, Existent\": {\n    \"Active Directory Error\": \"User not found in Active Directory. Update failed.\"\n  }\n}"
    TechTableMailer.alert_email(message)
  end

  def onboarding_permissions
    emp_trans = EmpTransaction.where(kind: "Onboarding").last
    emp = Employee.find(emp_trans.onboarding_infos.first.employee_id)
    TechTableMailer.permissions(emp_trans, emp)
  end

  def security_access_permissions
    emp_trans = EmpTransaction.where(kind: "Security Access").last
    if emp_trans.emp_sec_profiles.count > 0
      emp_id = emp_trans.emp_sec_profiles.first.employee_id
    elsif emp_trans.revoked_emp_sec_profiles.count > 0
      emp_id = emp_trans.revoked_emp_sec_profiles.first.employee_id
    end
    emp = Employee.find(emp_id)
    TechTableMailer.permissions(emp_trans, emp)
  end

  def equipment_permissions
    emp_trans = EmpTransaction.where(kind: "Equipment").last
    emp = Employee.find(emp_trans.emp_mach_bundles.first.employee_id)
    TechTableMailer.permissions(emp_trans, emp)
  end

  def offboard_notice
    emp = Employee.where('termination_date IS NOT NULL').first
    TechTableMailer.offboard_notice(emp)
  end

  def offboard_status
    emp_trans = EmpTransaction.where(kind: "Offboarding").last
    emp = Employee.where('termination_date IS NOT NULL').first
    TechTableMailer.offboard_status(emp)
  end

  def offboard_instructions
    emp = Employee.where('termination_date IS NOT NULL').first
    TechTableMailer.offboard_instructions(emp)
  end

  def onboard_instructions
    emp_trans = EmpTransaction.where(kind: "Onboarding").last
    emp = Employee.find(emp_trans.onboarding_infos.first.employee_id)
    TechTableMailer.onboard_instructions(emp)
  end
end
