class OnboardQuery
  def initialize(relation = Profile.includes([:employee, :department, department: :parent_org]).order("parent_orgs.name", "departments.name", "employees.last_name"))
    @relation = relation
  end

  def onboarded_this_week
    @relation.where("start_date BETWEEN ? AND ?", 7.days.ago, Date.today)
  end

  def onboarding
    @relation.where("start_date >= ?", Date.today)
  end

  def added_and_updated_onboards
    onboarding.map { |c|
      c if c.employee.last_changed_at >= summary_last_sent
    }.compact
  end

  def added_and_updated_offboards
    @relation.where("employees.termination_date >= ?", summary_last_sent).compact
  end

  private

  def summary_last_sent
    # cwday returns the day of calendar week (1-7, Monday is 1).
    3.days.ago if Date.today.cwday == 1
    1.day.ago
  end
end
