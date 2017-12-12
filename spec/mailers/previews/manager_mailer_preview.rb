class ManagerMailerPreview < ActionMailer::Preview
  def onboarding_permissions
    employee = Employee.where(status: "pending").last
    manager = Employee.find_by_employee_id(employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions("Onboarding", manager, employee)
  end

  def event_onboarding_permissions
    event = AdpEvent.where("adp_events.json LIKE '%worker.rehire%'").last
    profiler = EmployeeProfile.new
    employee = profiler.build_employee(event)
    manager = employee.manager
    ManagerMailer.permissions("Onboarding", manager, employee, event: event)
  end

  def onboarding_reminder
    employee = Employee.where("status LIKE ? AND manager_id IS NOT NULL", "pending").last
    manager = employee.manager
    ManagerMailer.reminder(manager, employee, "reminder")
  end

  def onboarding_reminder_escalation
    employee = Employee.where("status LIKE ? AND manager_id IS NOT NULL", "pending").last
    managers_manager = employee.manager.manager
    ManagerMailer.reminder(managers_manager, employee, "escalation")
  end

  def offboarding_permissions
    employee = Employee.where('termination_date IS NOT NULL').last
    manager = Employee.find_by_employee_id(employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions("Offboarding", manager, employee)
  end

  def offboarding_contractor
    employee = Employee.where('contract_end_date IS NOT NULL AND termination_date IS NULL').last
    manager = employee.manager
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
end
