module EmployeeService
  class ChangeHandler < Base
    def call
      return true if @employee.emp_deltas.blank?
      @delta = @employee.emp_deltas.last
      parse_changes
    end

    private

    def parse_changes
      reset_contract if changed_contract_end_date?
    end

    def changed_contract_end_date?
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
