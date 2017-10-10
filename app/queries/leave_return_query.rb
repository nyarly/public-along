class LeaveReturnQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def find_each(&block)
    @relation.
      where('leave_return_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow).
      find_each(&block)
  end
end
