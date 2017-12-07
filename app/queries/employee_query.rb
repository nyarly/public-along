class EmployeeQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def contract_end_reminder_group
    @relation.where("contract_end_date = ?
                     AND status LIKE ?
                     AND termination_date IS NULL",
              2.weeks.from_now.beginning_of_day,
              "active")
  end
end
