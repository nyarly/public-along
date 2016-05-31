namespace :employee do
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

  task :xml_to_ad => :environment do
    file = latest_xml_file

    if file.present?
      xml = XmlService.new(file)
      xml.parse_to_db
      new_hires = xml.new_hires
      existing_employees = xml.existing_employees

      ads = ActiveDirectoryService.new
      ads.create_disabled_accounts(new_hires)
      ads.update(existing_employees)
      trans = XmlTransaction.create(
        :name => File.basename(file),
        :checksum => checksum(file)
      )
    else
      puts "ERROR: No xml file to parse."
    end
  end
end

def latest_xml_file
  # Find all .xml files in lib/assets/ and use the file with the most recent date stamp
  file = nil
  filepath = nil
  hash = Hash.new { |k,v| k[v] = [] }
  Dir["lib/assets/*.xml"].each do |f|
    hash[f] = f.gsub(/\D/,"").to_i
  end
  hash.each { |k,v| filepath = k if v == hash.values.max }
  if XmlTransaction.where(:checksum => checksum(filepath)).empty?
    file = File.new(filepath)
  end
end

def in_time_window?(date, hour, zone)
  # TODO refactor this as a scope in Employee model
  start_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
  end_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, (hour + 1)))

  start_time <= DateTime.now.in_time_zone("UTC") && DateTime.now.in_time_zone("UTC") < end_time
end

def checksum(file_or_path)
  Digest::MD5.hexdigest(File.read(file_or_path))
end
