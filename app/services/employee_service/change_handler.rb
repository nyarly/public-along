module EmployeeService
  class ChangeHandler < Base
    def call
      return true if @employee.emp_deltas.blank?
      @delta = @employee.emp_deltas.last
      parse_changes
      @employee
    end

    private

    def parse_changes
      reset_contract if contract_end_date_changed?
      update_manager_permissions if manager_changed?
      send_security_access_form if has_new_position_changes? && !sent_email_recently?
    end

    def contract_end_date_changed?
      @delta.before.include? "contract_end_date"
    end

    def reset_contract
      @employee.request_status = "none" if extended_contract? && @employee.status == "active"
    end

    def extended_contract?
      @delta.before["contract_end_date"] < @delta.after["contract_end_date"] &&
      @delta.after["contract_end_date"] > 2.weeks.from_now
    end

    def update_manager_permissions
      GrantManagerAccess.new(@employee.manager).process! if @employee.manager.present?
    end

    def manager_changed?
      @delta.before.include? "manager_id"
    end

    def has_new_position_changes?
      @delta.before.include?("department_id") || @delta.before.include?("location_id") || @delta.before.include?("job_title_id")
    end

    def sent_email_recently?
      return false if @employee.emp_deltas.count == 1
      last_important_change = @employee.emp_deltas.important_changes[-2]
      return false if last_important_change.blank?
      last_form_sent_on = last_important_change.created_at
      last_form_sent_on >= Date.today
    end

    def send_security_access_form
      return false if @employee.status != "active"
      EmployeeWorker.perform_async("Security Access", employee_id: @employee.id)
    end
  end
end
