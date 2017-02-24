require 'tzinfo'
# set :output, "/path/to/my/cron_log.log"

# Every hour:
# - Run rake tasks that activate/deactivate employees in Active Directory according to time zone
# - Sync ADP data
every 1.hour do
  rake "employee:change_status"
  rake "adp:sync_all"
end

every :weekday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("9:00")) do
  rake "employee:onboard_report"
  rake "employee:job_change_report"
end

every :weekday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("18:00")) do
  rake "employee:offboard_report"
  rake "db:saba:update_csvs"
  rake "db:saba:sftp_drop"
end

# need to refactor this redundant code when we have time to test proper syntax
every :sunday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("18:00")) do
  rake "db:saba:update_csvs"
  rake "db:saba:sftp_drop"
end

every :monday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("18:00")) do
  rake "db:saba:update_csvs"
  rake "db:saba:sftp_drop"
end

every :tuesday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("18:00")) do
  rake "db:saba:update_csvs"
  rake "db:saba:sftp_drop"
end

every :wednesday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("18:00")) do
  rake "db:saba:update_csvs"
  rake "db:saba:sftp_drop"
end

every :thursday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("18:00")) do
  rake "db:saba:update_csvs"
  rake "db:saba:sftp_drop"
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
