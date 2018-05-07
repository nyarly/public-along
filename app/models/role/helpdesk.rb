class Role::Helpdesk < Role
  Role.register 'Helpdesk', self

  def set_abilities(ability)
    ability.can :manage, MachineBundle
    ability.can :manage, DeptSecProf
    ability.can :manage, SecurityProfile
    ability.can :manage, SecProfAccessLevel
    ability.can :manage, AccessLevel
    ability.can :manage, Application
    ability.can :new, EmpTransaction
    ability.can :read, Employee
    ability.can :read, EmpTransaction
    ability.can :read, EmpSecProfile
    ability.can :read, Department
    ability.can :autocomplete_name, Employee
    ability.can :autocomplete_email, Employee
    ability.can :create, Email
    ability.can :read, :new_hire
    ability.can :read, :offboard
    ability.can :read, :inactive
  end
end
