module EmployeeService
  class Onboard < Base
    attr_reader :employee

    def new_worker
      new_worker_ad_account
      UpdateEmailWorker.perform_async(employee.id)
      process_security_profiles
    end

    def re_onboard
      update_ad_account
      UpdateEmailWorker.perform_async(employee.id)
      process_security_profiles
    end

    def send_manager_form
      employee.wait!
      EmployeeWorker.perform_async("onboarding", employee_id: employee.id)
    end

    private

    def process_security_profiles
      GrantManagerAccess.new(employee.manager).process! if employee.manager.present?
      GrantManagerAccess.new(employee).process!
      GrantBasicSecProfile.new(employee).process!
      employee.security_profiles
    end

    def new_worker_ad_account
      ad = ActiveDirectoryService.new
      ad.create_disabled_accounts([employee])
    end

    def update_ad_account
      ad = ActiveDirectoryService.new
      ad.update([employee])
    end
  end
end
