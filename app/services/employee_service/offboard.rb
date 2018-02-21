module EmployeeService
  # Offboarding service groups
  class Offboard < Base
    attr_reader :employee
    attr_reader :results

    def prepare_termination
      TechTableMailer.offboard_notice(employee).deliver_now
      EmployeeWorker.perform_async('Offboarding', employee_id: employee.id)
    end

    def execute_termination
      deactivate_ad_account
      set_offboarded_time
      run_automated_offboard_tasks
    rescue StandardError => error
      Rails.logger.error "Termination process failed with #{error}"
    end

    private

    def deactivate_ad_account
      ad = ActiveDirectoryService.new
      ad.deactivate([employee])
    end

    def run_automated_offboard_tasks
      ApplicationService.new(employee).offboard_all_apps
    end

    def set_offboarded_time
      employee.update(offboarded_at: Time.now)
    end
  end
end
