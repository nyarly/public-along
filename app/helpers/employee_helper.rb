module EmployeeHelper
  def manager_form_type
    return "Onboarding" if status == "pending"
    return "Offboarding" if status == "active" && termination_date.present?
  end

  def manager_form_due
    return nil if request_status != "waiting"
    return onboarding_due_date if status == "pending"
    return offboarding_cutoff.strftime("%b %e, %Y") if status == "active"
  end

  def needs_security_profile_update?
    changed_at = self.emp_deltas.important_changes.present? ? self.emp_deltas.important_changes.reorder(:created_at).last.created_at : self.created_at
    updated_at = self.emp_transactions.present? ? self.emp_transactions.reorder(:created_at).last.created_at : self.created_at
    return changed_at > updated_at
  end
end
