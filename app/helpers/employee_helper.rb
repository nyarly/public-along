module EmployeeHelper
  def manager_form_type(employee)
    return "onboarding" if employee.status == "pending"
    return "offboarding" if offboard_in_progress?(employee)
    'job_change'
  end

  def manager_form_due(employee)
    return employee.onboarding_due_date.strftime("%B %e, %Y") if employee.status == "pending"
    return employee.offboarding_cutoff.strftime("%b %e, %Y") if offboard_in_progress?(employee)
  end

  def needs_security_profile_update?(employee)
    changed_at = employee.emp_deltas.important_changes.present? ? employee.emp_deltas.important_changes.reorder(:created_at).last.created_at : employee.created_at
    updated_at = employee.emp_transactions.present? ? employee.emp_transactions.reorder(:created_at).last.created_at : employee.created_at
    changed_at > updated_at
  end

  def is_contingent_worker?(employee)
    employee.worker_type.kind == "Temporary" || employee.worker_type.kind == "Contractor"
  end

  def offboard_in_progress?(employee)
    return false if employee.status != "active"
    return true if employee.termination_date.present?
    employee.contract_end_date.present? && employee.contract_end_date.between?(Date.today, 2.weeks.from_now)
  end

  def onboard_submitted(employee)
    onboards = employee.onboarding_infos
    return nil if employee.waiting? || onboards.blank?
    onboards.last.created_at
  end
end
