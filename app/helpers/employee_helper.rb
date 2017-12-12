module EmployeeHelper
  def manager_form_type(employee)
    return "Onboarding" if employee.status == "pending"
    return "Offboarding" if employee.status == "active" && employee.termination_date.present?
  end

  def manager_form_due(employee)
    return nil if employee.request_status != "waiting"
    return employee.onboarding_due_date.strftime("%B %e, %Y") if employee.status == "pending"
    return employee.offboarding_cutoff.strftime("%B %e, %Y") if employee.status == "active"
  end

  def needs_security_profile_update?(employee)
    changed_at = employee.emp_deltas.important_changes.present? ? employee.emp_deltas.important_changes.reorder(:created_at).last.created_at : employee.created_at
    updated_at = employee.emp_transactions.present? ? employee.emp_transactions.reorder(:created_at).last.created_at : employee.created_at
    return changed_at > updated_at
  end

  def is_contingent_worker?(employee)
    employee.worker_type.kind == "Temporary" || employee.worker_type.kind == "Contractor"
  end
end
