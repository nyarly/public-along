class Role::HumanResources < Role
  Role.register 'HumanResources', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :autocomplete_name, Employee
    ability.can :manage, Department
    ability.can :manage, Location
    ability.can :manage, ParentOrg
    ability.can :manage, WorkerType
    ability.can :create, Email
  end
end
