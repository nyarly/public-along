<% js = escape_javascript(
  render(partial: 'employees/employees_table', locals: { employees: @employees })
) %>
$("#filterrific_results").html("<%= js %>");
