class EmployeeQuery
  def initialize(relation = Employee.all)
    @relation = relation
  end

  def contract_end_reminder_group
    @relation.where("contract_end_date = ?
                     AND status LIKE ?
                     AND termination_date IS NULL",
      2.weeks.from_now.beginning_of_day,
      'active')
  end

  def active_regular_workers
    Employee.where(status: 'active').joins(:profiles).merge(Profile.regular_worker_type).to_a.uniq
  end

  # P&C wants an alert for contract end dates 3 weeks in advance
  def hr_contractor_notices
    @relation.where("contract_end_date = ?
                     AND status LIKE ?
                     AND termination_date IS NULL",
              3.weeks.from_now.beginning_of_day,
              'active')
  end
end
