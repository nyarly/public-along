class ManagerMailerPreview < ActionMailer::Preview

  def onboarding_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    puts employee.profiles.inspect
    manager = Employee.find_by_employee_id(employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions("Onboarding", manager, employee)
  end

  def offboarding_permissions
    employee = Employee.where('termination_date IS NOT NULL').last
    manager = Employee.find_by_employee_id(employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions("Offboarding", manager, employee)
  end

  def sec_access_permissions
    important_change = EmpDelta.important_changes.last
    employee = Employee.find(important_change.employee_id)
    manager = Employee.find_by_employee_id(employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions("Security Access", manager, employee)
  end

  def equipment_permissions
    employee = Employee.unscoped.order('created_at ASC').last
    manager = Employee.find_by_employee_id(employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions("Equipment", manager, employee)
  end

  def event_onboarding_permissions
    event = AdpEvent.where("adp_events.json LIKE '%worker.rehire%'").last
    profiler = EmployeeProfile.new
    employee = profiler.build_employee(event)
    manager = employee.manager
    ManagerMailer.permissions("Onboarding", manager, employee, event: event)
  end
end
