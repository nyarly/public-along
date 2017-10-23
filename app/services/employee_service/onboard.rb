module EmployeeService
  class Onboard < Base
    def process!
      # TODO: add basic sec profile should remove old if worker type changed
      # ManagerAccessService.new(@employee.manager).process! if @employee.manager.present?
      # ManagerAccessService.new(@employee).process!
      BasicSecurityProfileService.new(@employee).process!
      EmployeeWorker.perform_async("Onboarding", employee_id: @employee.id)
    end
  end
end
