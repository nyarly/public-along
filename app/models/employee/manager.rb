module Employee::Manager
  def manager
    Employee.find_by_employee_id(manager_id) if manager_id
  end

  def Employee.direct_reports_of(manager_emp_id)
    joins(:profiles).where("profiles.manager_id LIKE ?", manager_emp_id)
  end

  def check_manager
    manager = self.manager

    if manager.present? && !Employee.managers.include?(manager)
      sp = SecurityProfile.find_by(name: "Basic Manager")

      emp_trans = EmpTransaction.new(
        kind: "Service",
        notes: "Manager permissions added by Mezzo",
        employee_id: manager.id
      )

      emp_trans.emp_sec_profiles.build(
        security_profile_id: sp.id
      )

      emp_trans.save!

      if emp_trans.emp_sec_profiles.count > 0
        sas = SecAccessService.new(emp_trans)
        sas.apply_ad_permissions
      end
    end
  end
end
