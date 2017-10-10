class OffboardReportQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def find_each(&block)
    @relation.
      where('employees.termination_date BETWEEN ? AND ?', Date.today - 2.weeks, Date.today).
      find_each(&block)
  end
end
