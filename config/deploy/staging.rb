server "workday-integration-pp-sf-01.otcorp.opentable.com", roles: [:web, :app, :db], primary: true #need a new mezzo hostname

set :deploy_to, "/var/www/mezzo"
set :branch,    :staging
