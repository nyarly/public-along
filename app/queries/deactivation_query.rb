class DeactivationQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def find_each(&block)
    @relation.
      where('contract_end_date BETWEEN ? AND ?
             OR leave_start_date BETWEEN ? AND ?
             OR termination_date BETWEEN ? AND ?',
             Date.yesterday, Date.tomorrow,
             Date.yesterday, Date.tomorrow,
             Date.yesterday, Date.tomorrow).
      find_each(&block)
  end
end
