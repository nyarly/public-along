class OffboardQuery
  def initialize(relation = Profile.includes([:employee, :department, department: :parent_org])
                                   .order('parent_orgs.name', 'departments.name', 'employees.last_name'))
    @relation = relation
  end

  def report_group
    offboards_from_today_to_date(2.weeks.ago)
  end

  def added_and_updated_offboards
    offboards_from_today_to_date(summary_last_sent)
  end

  private

  def offboards_from_today_to_date(starting_date)
    relation.where("employees.termination_date BETWEEN ? AND ?
                    OR employees.offboarded_at BETWEEN ? AND ?
                    OR (employees.contract_end_date BETWEEN ? AND ?
                        AND (employees.termination_date BETWEEN ? AND ?
                        OR employees.termination_date IS NULL))",
      starting_date, Date.today,
      starting_date, Date.today,
      starting_date, Date.today,
      starting_date, Date.today)
  end

  def summary_last_sent
    # cwday returns the day of calendar week (1-7, Monday is 1).
    3.days.ago if Date.today.cwday == 1
    1.day.ago
  end

  attr_reader :relation
end
