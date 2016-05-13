# set :output, "/path/to/my/cron_log.log"

# Every hour run rake tasks that activate/deactivate employees in Active Directory according to time zone
every 1.hour do
  rake "employees:change_status"
end
