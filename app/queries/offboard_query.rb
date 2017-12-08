class OffboardQuery
  def initialize(relation = Profile.includes([:employee, :department, department: :parent_org]).order("parent_orgs.name", "departments.name", "employees.last_name"))
    @relation = relation
  end

  def added_and_updated_offboards
    @relation.where("employees.termination_date BETWEEN ? AND ?", summary_last_sent, Date.today).compact
  end

  private

  def summary_last_sent
    # cwday returns the day of calendar week (1-7, Monday is 1).
    3.days.ago if Date.today.cwday == 1
    1.day.ago
  end
end
