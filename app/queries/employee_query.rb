class EmployeeQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def active_regular_workers
    Employee.where(status: 'active').joins(:profiles)
      .merge(Profile.regular_worker_type).to_a.uniq
  end
end
