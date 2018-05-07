<% js = escape_javascript(
  render(partial: 'employees/offboards/list', locals: { offboards: @offboards })
) %>
$("#filterrific_results").html("<%= js %>");
