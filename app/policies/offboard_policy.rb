class OffboardPolicy
  attr_reader :employee

  def initialize(employee)
    @employee = employee
  end

  def offboarded_contractor?
    employee.terminated? && employee.needs_contract_end_confirmation?
  end

  def offboarded?
    employee.offboarded_at.present? && employee.terminated?
  end
end
