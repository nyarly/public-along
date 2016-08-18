class Role::HumanResources < Role::Basic
  Role.register 'HumanResources', self

  def set_abilities(ability)
    super

    ability.can :create, Employee
    ability.can :update, Employee
    ability.can :manage, Department
    ability.can :manage, Location
    ability.can :manage, EmpTransaction, :user_id => user.id
  end
end
