class EmployeeWorker
  include Sidekiq::Worker

  def perform(action, employee)
    @employee = employee
    @manager = Employee.find_by(employee_id: @employee.manager_id)

    if action == :create
      @mailer = ManagerMailer.permissions(@manager, @employee, "Onboarding")
    elsif action == :update
      # Re-hire
      if @employee.hire_date_changed? && @employee.termination_date_changed?
        @mailer = ManagerMailer.permissions(@manager, @employee, "Onboarding")
      # Job Change requiring security access changes
      elsif @employee.manager_id_changed? || @employee.business_title_changed?
        @mailer = ManagerMailer.permissions(@manager, @employee, "Security Access")
      end
    end if @manager.present?

    @mailer.deliver_now if @mailer.present?
  end
end
