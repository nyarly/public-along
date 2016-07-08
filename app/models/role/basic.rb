class Role::Basic < Role
  Role.register 'Basic', self

  def set_abilities(ability)
    ability.can :read, Employee
  end

end
