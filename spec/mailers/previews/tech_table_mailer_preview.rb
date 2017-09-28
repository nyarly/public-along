class TechTableMailerPreview < ActionMailer::Preview
  def alert_email
    message = "{\n  \"mbros@opentable.com, Mario, \": {\n    \"last_name\": [\n      \"can't be blank\"\n    ]\n  },\n  \", Luddite, Johnson\": {\n    \"Active Directory Error\": \"No email to match to AD records\"\n  },\n  \"nonexistent@opentable.com, Non, Existent\": {\n    \"Active Directory Error\": \"User not found in Active Directory. Update failed.\"\n  }\n}"
    TechTableMailer.alert_email(message)
  end

  def security_access_permissions
    emp_delta = EmpDelta.important_changes.last
    employee = Employee.find(emp_delta.employee_id)
    emp_trans = employee.emp_transactions.where(kind: "Security Access").last
    TechTableMailer.permissions(emp_trans, employee)
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
    emp = Employee.where('termination_date IS NOT NULL').first
    results = {"Google Apps"=>"completed",
               "Admin"=>"success",
               "Admin_EU"=>"success",
               "Admin_Asia"=>"success",
               "OTAnywhere"=>"success",
               "OTAnywhere_EU"=>"success",
               "OTAnywhere_Asia"=>"success",
               "GOD"=>"failed"}
    TechTableMailer.offboard_status(emp, results)
  end

  def offboard_instructions
    emp = Employee.where('termination_date IS NOT NULL').first
    TechTableMailer.offboard_instructions(emp)
  end

  def onboard_instructions
    emp_trans = EmpTransaction.where(kind: "Onboarding").last
    TechTableMailer.onboard_instructions(emp_trans)
  end

  def rehire_onboard_instructions
    # employee = FactoryGirl.create(:employee,
    #   first_name: "Trish",
    #   hire_date: Date.new(2017, 1, 1),
    #   status: "Pending")
    # old_profile = FactoryGirl.create(:profile,
    #   employee: employee,
    #   profile_status: "Terminated",
    #   start_date: Date.new(2017, 1, 1),
    #   end_date: Date.new(2017, 6, 1))
    # new_profile = FactoryGirl.create(:profile,
    #   employee: employee,
    #   profile_status: "Pending",
    #   start_date: Date.new(2017, 7, 1))
    # emp_transaction = FactoryGirl.create(:emp_transaction,
    #   employee: employee,
    #   kind: "Onboarding")

        emp_trans = EmpTransaction.where(kind: "Onboarding").last


    TechTableMailer.onboard_instructions(emp_trans)
  end
end
