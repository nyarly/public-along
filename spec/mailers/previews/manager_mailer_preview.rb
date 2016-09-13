class ManagerMailerPreview < ActionMailer::Preview
  def onboarding_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Onboarding")
  end

  def offboarding_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Offboarding")
  end

  def sec_access_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Security Access")
  end

  def equipment_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Equipment")
  end
end
