require 'tzinfo'

# Every hour:
# - Run rake tasks that activate/deactivate employees in Active Directory according to time zone
# - Sync ADP data
every 1.hour do
  rake "employee:change_status"
  rake "adp:sync_all"
  rake "employee:send_onboarding_reminders"
end

# 4pm UTC / 9am PT
every :day, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("9:00")) do
  rake "employee:send_contract_end_notifications"
  rake "notify:hr_contract_end"
end

# 4pm UTC / 9am PT
every :weekday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("9:00")) do
  rake "report:daily_onboards"
end

# 4pm UTC / 9am PT
every :day, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("9:00")) do
  rake "report:job_changes"
end

# 11pm UTC / 4pm PT
every :weekday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("16:00")) do
  rake "report:offboards"
end

# 2am UTC / 7pm PT
every [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday], at: '2:00am' do
  rake "db:saba:update_csvs"
end

# 2:10am UTC / 7:10 PT
every [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday], at: '2:10am' do
  rake "db:saba:sftp_drop"
end

# 5am UTC / 10pm PT
every :day, at: '5:00am' do
  rake "betterworks:sftp_drop"
end

# 6am UTC / 11pm PT
every :weekday, at: '6:00am' do
  rake "report:missed_terminations"
end

# 11pm UTC / 4pm PT
every :friday, at: TZInfo::Timezone.get("America/Los_Angeles").local_to_utc(Time.parse("16:00")) do
  rake "report:weekly_onboards"
end

# 3:30am UTC / 8:30pm PT
every :saturday, at: '3:30am' do
  rake "adp:update_all_email"
end

# 6:30am UTC / 11:30pm PT
every :sunday, at: '6:30am' do
  rake "report:missed_deactivations"
end
