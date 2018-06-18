class Role::Security < Role
  Role.register 'Security', self

  def set_abilities(ability)
    ability.can [:read, :direct_reports, :autocomplete_name, :autocomplete_email], Employee
    ability.can :read, :new_hire
    ability.can :read, :offboard
    ability.can :read, :inactive
    ability.can :read, SecurityProfile
    ability.can :read, AccessLevel
    ability.can :read, Application
  end
end
