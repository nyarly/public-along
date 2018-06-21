class Role::Admin < Role
  Role.register 'Admin', self

  def set_abilities(ability)
    ability.can :manage, Approval
    ability.can :manage, Employee
    ability.can :manage, MachineBundle
    ability.can :manage, Location
    ability.can :manage, Department
    ability.can :manage, DeptSecProf
    ability.can :manage, SecurityProfile
    ability.can :manage, SecProfAccessLevel
    ability.can :manage, AccessLevel
    ability.can :manage, Application
    ability.can :manage, EmpTransaction
    ability.can :manage, EmpSecProfile
    ability.can :manage, ParentOrg
    ability.can :manage, WorkerType
    ability.can :create, Email
    ability.can :manage, Profile
    ability.can :read, :new_hire
    ability.can :read, :offboard
    ability.can :read, :inactive
  end
end
