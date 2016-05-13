namespace :employee do
  task :change_status do
    ads = ActiveDirectoryService.new
    new_hires = []
    terminations = []

    Employee.all.each do |e|
      zone = tz_by_country(e.country)
      if e.hire_date && in_time_window?(e.hire_date, 3, zone)
        new_hires << e
      elsif e.contract_end_date && in_time_window?(e.contract_end_date, 21, zone)
        terminations << e
      end
    end

    ads.activate(new_hires)
    ads.deactivate(terminations)
  end
end

def tz_by_country(co)
  # US has the broadest time zone spectrum, Pacific time is a sufficient middle ground to capture business hours between NYC and Hawaii
  co == 'US' ? "America/Los_Angeles" : TZInfo::Country.get(co).zone_identifiers.first
end

def in_time_window?(date, hour, zone)
  start_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
  end_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, (hour + 1)))

  start_time <= DateTime.now.in_time_zone("UTC") && DateTime.now.in_time_zone("UTC") < end_time
end
