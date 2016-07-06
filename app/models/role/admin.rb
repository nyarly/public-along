class Role::Admin < Role::Basic
  Role.register 'Admin', self

  def set_abilities(ability)
    super

    ability.can :manage, Department
    ability.can :manage, Employee
    # ability.can :manage, MachineBundle
    # ability.can :manage, OrgRole
    # ability.can :manage, OrgApp
  end
end
