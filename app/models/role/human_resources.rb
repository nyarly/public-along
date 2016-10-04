class Role::HumanResources < Role
  Role.register 'HumanResources', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :create, Employee
    ability.can :update, Employee
    ability.can :manage, Department
    ability.can :manage, Location
  end
end
