class Role::Security < Role
  Role.register 'Security', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :direct_reports, Employee
    ability.can :autocomplete_name, Employee
    ability.can :read, Profile
    ability.can :read, :new_hire
    ability.can :read, :offboard
    ability.can :read, :inactive
  end
end
