class ManagerMailerPreview < ActionMailer::Preview
  def onboarding_permissions
    employee = Employee.first
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Onboarding")
  end

  def sec_access_permissions
    employee = Employee.first
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Security Access")
  end

  def equipment_permissions
    employee = Employee.first
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Equipment")
  end
end
