class Role::HumanResources < Role::Basic
  Role.register 'HumanResources', self

  def set_abilities(ability)
    super

    ability.can :read, Employee
  end
end
