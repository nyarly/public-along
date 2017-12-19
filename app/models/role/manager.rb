class Role::Manager < Role
  Role.register 'Manager', self

  def set_abilities(ability)
    ability.can :read, Employee
    ability.can :direct_reports, Employee.all do |e|
      e.id == user.employee_id || ManagementTreeQuery.new(e).up.include?(user.employee_id)
    end
    ability.can :new, EmpTransaction, Employee.all do |e|
      ManagementTreeQuery.new(e.employee).up.include? user.employee_id
    end
    ability.can :show, EmpTransaction, Employee.all do |e|
      ManagementTreeQuery.new(e.employee).up.include? user.employee_id
    end
    ability.can :create, EmpTransaction, Employee.all do |e|
      ManagementTreeQuery.new(e.employee).up.include? user.employee_id
    end
    ability.can :create, ManagerEntry, Employee.all do |e|
      ManagementTreeQuery.new(e.employee).up.include? user.employee_id
    end
    ability.can :autocomplete_name, Employee
    ability.can :autocomplete_email, Employee
  end
end

