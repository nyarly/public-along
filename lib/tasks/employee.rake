namespace :employee do
  desc "change status of employees (activate/deactivate)"
  task :change_status => :environment do
    activations = []
    deactivations = []

    Employee.activation_group.each do |e|
      # Collect employees to activate if it is 3-4am on their hire date or leave return date in their respective nearest time zone
      if e.leave_return_date
        activations << e if in_time_window?(e.leave_return_date, 3, e.nearest_time_zone)
      else
        activations << e if in_time_window?(e.hire_date, 3, e.nearest_time_zone)
      end
    end

    Employee.deactivation_group.each do |e|
      # Collect employees to deactivate if it is 9-10pm on their end date or day before leave start date in their respective nearest time zone
      if e.leave_start_date
        deactivations << e if in_time_window?(e.leave_start_date - 1.day, 21, e.nearest_time_zone)
      else
        deactivations << e if in_time_window?(e.contract_end_date, 21, e.nearest_time_zone)
      end
    end

    ads = ActiveDirectoryService.new
    ads.activate(activations)
    ads.deactivate(deactivations)
  end

  desc "parse latest xml file to active directory"
  task :xml_to_ad => :environment do
    xml = XmlService.new

    if xml.doc.present?
      xml.parse_to_ad
    else
      TechTableMailer.alert_email("ERROR: No xml file to parse. Check to see if Workday is sending xml files to the designated sFTP.").deliver_now
    end
  end

  desc "update active directory against mezzo employee db"
  task :update_ad => :environment do
    ads = ActiveDirectoryService.new
    ads.create_disabled_accounts(Employee.create_group)
    ads.update(Employee.update_group)
  end
end

def in_time_window?(date, hour, zone)
  # TODO refactor this as a scope in Employee model
  start_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
  end_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, (hour + 1)))

  start_time <= DateTime.now.in_time_zone("UTC") && DateTime.now.in_time_zone("UTC") < end_time
end


