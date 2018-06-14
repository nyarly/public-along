class Role::Manager < Role
  Role.register 'Manager', self

  def set_abilities(ability)
    ability.can [:autocomplete_name, :autocomplete_email], Employee
    ability.can [:read, :update, :direct_reports], user.employee.self_and_descendants
    ability.can [:read, :create], EmpTransaction.where('employee_id IN (?)', user.employee.self_and_descendants)
  end
end
