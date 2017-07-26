class ManagerMailerPreview < ActionMailer::Preview

  def onboarding_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Onboarding")
  end

  def offboarding_permissions
    employee = Employee.where('termination_date IS NOT NULL').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Offboarding")
  end

  def sec_access_permissions
    important_change = EmpDelta.important_changes.last
    employee = Employee.find(important_change.employee_id)
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Security Access")
  end

  def equipment_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee, "Equipment")
  end
end
