class Role::Admin < Role::Basic
  Role.register 'Admin', self

  def set_abilities(ability)
    super

    ability.can :manage, Employee
    ability.can :manage, MachineBundle
    ability.can :manage, Location
    ability.can :manage, Department
    ability.can :manage, DeptSecProf
    ability.can :manage, SecurityProfile
    ability.can :manage, SecProfAccessLevel
    ability.can :manage, AccessLevel
    ability.can :manage, Application
    ability.can :manage, Transaction
    ability.can :manage, EmpSecProfile
  end
end
