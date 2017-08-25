class Role::Manager < Role
  Role.register 'Manager', self

  def set_abilities(ability)
    ability.can :read, Employee, manager_id: user.employee_id
    ability.can :create, Employee, manager_id: user.employee_id
    ability.can :update, Employee, manager_id: user.employee_id
    ability.can :create, Profile, manager_id: user.employee_id
    ability.can :new, EmpTransaction
    ability.can :show, EmpTransaction, :user_id => user.id
    ability.can :create, EmpTransaction, :user_id => user.id
    ability.can :create, ManagerEntry, :user_id => user.id
    ability.can :autocomplete_name, Employee
    ability.can :autocomplete_email, Employee
  end
end
