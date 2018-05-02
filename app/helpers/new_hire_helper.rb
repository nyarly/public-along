module NewHireHelper
  def sort_link(table_name, column, display_name = nil)
    display_name ||= column.titleize
    link_column = table_name + '.' + column
    currently_sorted_by = currently_sorted_by?(link_column, sort_column)
    currently_asc = currently_asc?(sort_direction)

    direction = currently_sorted_by && currently_asc ? 'desc' : 'asc'
    icon = currently_asc ? 'ui-icon ui-icon-caret-1-n' : 'ui-icon ui-icon-caret-1-s'
    icon = currently_sorted_by ? icon : ''

    link_to "#{display_name} <span class='#{icon}'></span>".html_safe, { table_name: table_name, column: column, direction: direction }
  end

  private

  def currently_asc?(direction)
    direction == 'asc'
  end

  def currently_sorted_by?(link_column, sort_column)
    link_column == sort_column
  end

  def onboard_link(employee)
    transaction = employee.onboarding_infos.last.try(:emp_transaction)
    if transaction
      link_to 'Form', emp_transaction_path(transaction)
    else
    end
  end
end
