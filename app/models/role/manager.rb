class Role::Manager < Role::Basic
  Role.register 'Manager', self

  def set_abilities(ability)
    super

    ability.can :read, Employee
    ability.can :new, EmpTransaction
    ability.can :create, EmpTransaction, :user_id => user.id
    ability.can :create, ManagerEntry, :user_id => user.id
  end
end
