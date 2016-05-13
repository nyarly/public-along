namespace :employee do
  task :change_status do
    new_hires = []
    terminations = []

    Employee.activation_group.each do |e|
      # Collect employees to activate if it is 3-4am on their hire date in their respective nearest time zone
      new_hires << e if in_time_window?(e.hire_date, 3, e.nearest_time_zone)
    end

    Employee.deactivation_group.each do |e|
      # Collect employees to deactivate if it is 9-10pm on their end date in their respective nearest time zone
      terminations << e if in_time_window?(e.contract_end_date, 21, e.nearest_time_zone)
    end

    ads = ActiveDirectoryService.new
    ads.activate(new_hires)
    ads.deactivate(terminations)
  end
end

def in_time_window?(date, hour, zone)
  # TODO refactor this as a scope in Employee model
  start_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
  end_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, (hour + 1)))

  start_time <= DateTime.now.in_time_zone("UTC") && DateTime.now.in_time_zone("UTC") < end_time
end
