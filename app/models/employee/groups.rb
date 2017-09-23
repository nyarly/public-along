module Employee::Groups
  def activation_group
    where('hire_date BETWEEN ? AND ? OR leave_return_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow)
  end

  def deactivation_group
    where('contract_end_date BETWEEN ? AND ? OR leave_start_date BETWEEN ? AND ? OR termination_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow)
  end

  def full_termination_group
    where('termination_date BETWEEN ? AND ?', 8.days.ago, 7.days.ago)
  end

  def onboarding_report_group
    where('hire_date >= ?', Date.today)
  end

  def offboarding_report_group
    where('employees.termination_date BETWEEN ? AND ?', Date.today - 2.weeks, Date.today)
  end

  def onboarding_reminder_group
    reminder_group = []
    missing_onboards = Employee.where(status: "pending").joins('LEFT OUTER JOIN emp_transactions ON employees.id = emp_transactions.employee_id').group('employees.id').having('count(emp_transactions) = 0')

    missing_onboards.each do |e|
      reminder_date = e.onboarding_due_date.to_date - 1.day
      if reminder_date.between?(Date.yesterday, Date.tomorrow)
        reminder_group << e
      end
    end
    reminder_group
  end

  def managers
    joins(:emp_sec_profiles)
    .where('emp_sec_profiles.security_profile_id = ?', SecurityProfile.find_by(name: 'Basic Manager').id)
  end
end
