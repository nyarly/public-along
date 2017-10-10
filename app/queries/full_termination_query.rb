class FullTerminationQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def find_each(&block)
    @relation.
      where('termination_date BETWEEN ? AND ?', 8.days.ago, 7.days.ago).
      find_each(&block)
  end
end
