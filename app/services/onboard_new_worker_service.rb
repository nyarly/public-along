class OnboardNewWorkerService
  def initialize(employee)
    @employee = employee
  end

  def process!
    # ManagerAccessService.new(@employee.manager).process! if @employee.manager.present?
    # ManagerAccessService.new(@employee).process!
    BasicSecurityProfileService.new(@employee).process!
    EmployeeWorker.perform_async("Onboarding", employee_id: @employee.id)
  end
end
