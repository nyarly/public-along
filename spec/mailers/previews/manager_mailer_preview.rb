class ManagerMailerPreview < ActionMailer::Preview
  def permissions
    employee = Employee.first
    manager = Employee.find_by(employee_id: employee.manager_id) if employee && employee.manager_id
    ManagerMailer.permissions(manager, employee)
  end
end
