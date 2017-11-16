module EmployeeService
  class ChangeHandler < Base
    def call
      return true if @employee.emp_deltas.blank?
      @delta = @employee.emp_deltas.last
      parse_changes
    end

    private

    def parse_changes
      reset_contract if contract_end_date_changed?
      update_manager_permissions if manager_changed?
    end

    def update_manager_permissions
      GrantManagerAccess.new(@employee.manager).process! if @employee.manager.present?
    end

    def manager_changed?
      @delta.before.include? "manager_id"
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
  end
end
