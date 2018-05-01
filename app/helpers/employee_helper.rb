module EmployeeHelper
  def manager_form_type(employee)
    return "Onboarding" if employee.status == "pending"
    return "Offboarding" if offboard_in_progress?(employee)
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

  def sort_link(table_name, column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    icon = sort_direction == "asc" ? "ui-icon-caret-1-n" : "ui-icon-caret-1-s"
    icon = column == sort_column ? icon : ""
    link_to "#{title} <span class='#{icon}'></span>".html_safe, {table_name: table_name, column: column, direction: direction}
  end
end
