class OnboardQuery
  def initialize(onboard_scope, relation = Profile.includes([:department, department: :parent_org]))
    @onboard_scope = onboard_scope
    @relation = relation
  end

  def all
    @relation.public_send(@onboard_scope).sort_by_parent_department
  end
end
