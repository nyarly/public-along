class Role::HumanResources < Role::Basic
  Role.register 'HumanResources', self

  def set_abilities(ability)
    super

    ability.can :create, Employee
    ability.can :update, Employee
    # ability.can :manage, Employee if :manager_id == user.employee_id
    ability.can :manage, Department
    ability.can :manage, Location
    # Move to Manager Abilities
    ability.can :new, EmpTransaction
    ability.can :create, EmpTransaction, :user_id => user.id
    ability.can :create, ManagerEntry, :user_id => user.id
  end
end
