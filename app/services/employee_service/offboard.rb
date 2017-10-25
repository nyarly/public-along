module EmployeeService
  class Offboard < Base
    def prepare_termination
      TechTableMailer.offboard_notice(@employee).deliver_now
      EmployeeWorker.perform_async("Offboarding", employee_id: @employee.id)
    end
  end
end
