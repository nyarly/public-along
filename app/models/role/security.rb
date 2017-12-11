class Role::Security < Role
  Role.register 'Security', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :direct_reports, Employee
    ability.can :autocomplete_name, Employee
    ability.can :read, MachineBundle
    ability.can :read, Location
    ability.can :read, Department
    ability.can :read, DeptSecProf
    ability.can :read, SecurityProfile
    ability.can :read, SecProfAccessLevel
    ability.can :read, AccessLevel
    ability.can :read, Application
    ability.can :read, EmpTransaction
    ability.can :read, EmpSecProfile
    ability.can :read, ParentOrg
    ability.can :read, WorkerType
    ability.can :read, Profile
  end
end
