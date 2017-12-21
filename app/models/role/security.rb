class Role::Security < Role
  Role.register 'Security', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :direct_reports, Employee.all do |e|
      e.id == user.employee_id || ManagementTreeQuery.new(e).up.include?(user.employee_id)
    end
    ability.can :autocomplete_name, Employee
    ability.can :read, Profile
  end
end
