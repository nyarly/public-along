class Role::Security < Role
  Role.register 'Security', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :direct_reports, Employee
    ability.can :autocomplete_name, Employee
    ability.can :read, Profile
  end
end
