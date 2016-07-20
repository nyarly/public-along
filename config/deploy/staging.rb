server "pp-sf-mezzo-01.otcorp.opentable.com", roles: [:web, :app, :db], primary: true

set :deploy_to, "/var/www/mezzo"
set :branch,    :staging
set :stage,     :staging
