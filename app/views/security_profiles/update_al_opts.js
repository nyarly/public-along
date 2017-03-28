 $('#access_level_name_select').empty()
  .append("<%= escape_javascript (render partial: 'update_al_opts') %>")