class OnboardQuery
  def initialize(relation = Profile.includes([:department, department: :parent_org]).order("parent_orgs.name", "departments.name"))
    @relation = relation
  end

  def onboarded_this_week
    @relation.where("start_date BETWEEN ? AND ?", 7.days.ago, Date.today)
  end

  def onboarding
    @relation.where("start_date >= ?", Date.today)
  end
end
