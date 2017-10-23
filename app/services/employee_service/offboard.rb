module EmployeeService
  class Offboard < Base
    def prepare_termination
      TechTableMailer.offboard_notice(self).deliver_now
      EmployeeWorker.perform_async("Offboarding", employee_id: self.id)
    end
  end
end
