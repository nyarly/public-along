$('#sp_access_levels').append("<%= escape_javascript (render partial: 'sp_access_level', locals: { sp_access_level: @sp_access_level}) %>")
