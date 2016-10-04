class Role::Helpdesk < Role
  Role.register 'Helpdesk', self

  def set_abilities(ability)
    ability.can :manage, MachineBundle
    ability.can :manage, DeptSecProf
    ability.can :manage, SecurityProfile
    ability.can :manage, SecProfAccessLevel
    ability.can :manage, AccessLevel
    ability.can :manage, Application
    ability.can :read, Employee
    ability.can :read, EmpTransaction
    ability.can :read, EmpSecProfile
  end
end
