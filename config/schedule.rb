# set :output, "/path/to/my/cron_log.log"

# Every hour run rake tasks that activate/deactivate employees in Active Directory according to time zone
every 1.hour do
  rake "employee:change_status"
end

# Suspended until Workday returns
# Every 10 minutes check if a new xml file has been dropped in lib/assets and parse to db & AD if found
# every 10.minutes do
#   rake "employee:xml_to_ad"
# end

# Suspended until we need a mass update,
# Right now create and updates are happening indiviually in the employeecontroller
# Every minute update Active Directory with changes to Mezzo employee DB
# every 1.minute do
#   rake "employee:update_ad"
# end
