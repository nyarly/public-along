class Role::Manager < Role::Basic
  Role.register 'Manager', self

  def set_abilities(ability)
    super

    ability.can :read, Employee
    ability.can :manage, EmpTransaction, :user_id => user.id
  end
end
