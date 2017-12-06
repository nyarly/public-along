class OffboardPolicy
  def initialize(employee)
    @employee = employee
  end

  def offboarded_contractor?
    @employee.terminated? && @employee.needs_contract_end_confirmation?
  end
end
