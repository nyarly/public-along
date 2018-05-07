<% js = escape_javascript(
  render(partial: 'employees/new_hires/list', locals: { new_hires: @new_hires })
) %>
$("#filterrific_results").html("<%= js %>");
