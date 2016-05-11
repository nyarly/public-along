server "workday-integration-pp-sf-01.otcorp.opentable.com", roles: [:web, :app, :db], primary: true

set :deploy_to, "/var/www/workday_integration"
set :branch,    :staging
