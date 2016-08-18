class TechTableMailerPreview < ActionMailer::Preview
  def alert_email
    message = "{\n  \"mbros@opentable.com, Mario, \": {\n    \"last_name\": [\n      \"can't be blank\"\n    ]\n  },\n  \", Luddite, Johnson\": {\n    \"Active Directory Error\": \"No email to match to AD records\"\n  },\n  \"nonexistent@opentable.com, Non, Existent\": {\n    \"Active Directory Error\": \"User not found in Active Directory. Update failed.\"\n  }\n}"
    TechTableMailer.alert_email(message)
  end

  def onboarding_email
    emp_trans = EmpTransaction.last
    emp = Employee.find(emp_trans.emp_sec_profiles.first.employee_id)
    TechTableMailer.onboarding_email(emp_trans, emp)
  end
end
