class EmployeePolicy
  attr_reader :employee

  def initialize(employee)
    @employee = employee
  end

  def is_conversion?
    employee.active? &&
    employee.profiles.count > 1 &&
    employee.profiles.where(profile_status: 'pending').count >= 1
  end

  def manager?
    employee.direct_reports.count >= 1
  end
end
