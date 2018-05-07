<% js = escape_javascript(
  render(partial: 'employees/inactives/list', locals: { inactives: @inactives })
) %>
$("#filterrific_results").html("<%= js %>");
