class ActivationPolicy
  def initialize(employee, worker_type_kind)
    @employee = employee
    @worker_type_kind = worker_type_kind
  end

  def allowed?
    record_complete? && onboarded?
  end

  # Before activating, make sure contract workers have contract end date
  def record_complete?
    return true if @worker_type_kind == "Regular"
    @employee.contract_end_date.present?
  end

  def onboarded?
    @employee.request_status == "completed" || @employee.request_status == "none"
  end
end



