class Role::Helpdesk < Role
  Role.register 'Helpdesk', self

  def set_abilities(ability)
    ability.can :manage, MachineBundle
    ability.can :manage, DeptSecProf
    ability.can :manage, SecurityProfile
    ability.can :manage, SecProfAccessLevel
    ability.can :manage, AccessLevel
    ability.can :manage, Application
    ability.can :generate, OffboardCommand
    ability.can :new, EmpTransaction
    ability.can :read, Employee
    ability.can :read, EmpTransaction
    ability.can :read, EmpSecProfile
    ability.can :read, Department
    ability.can :autocomplete_name, Employee
  end
end
