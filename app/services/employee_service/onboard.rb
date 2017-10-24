module EmployeeService
  class Onboard < Base
    def process!
      GrantManagerAccess.new(@employee.manager).process! if @employee.manager.present?
      GrantManagerAccess.new(@employee).process!
      GrantBasicSecProfile.new(@employee).process!
      EmployeeWorker.perform_async("Onboarding", employee_id: @employee.id)
      @employee.security_profiles
    end
  end
end
