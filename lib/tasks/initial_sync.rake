require 'csv'
require 'pp'

namespace :sync do
  desc "initial employee info sync from csv, ex rake csv['/this/path']"
  task :csv, [:path] => :environment do |t, args|
    errors = {}
    ads = ActiveDirectoryService.new

    if args.path
      csv_text = File.read(args.path)
    else
      raise "You must provide a path to a .csv file"
    end

    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      row_attrs = row.to_hash
      # Create the worker in the DB
      e = Employee.find_or_create_by(:email => row_attrs["email"])
      # Convert Cost Center info to Department
      row_attrs[:department_id] = Department.find_by(:name => row_attrs["cost_center"]).id
      ["cost_center", "cost_center_id"].each do |k|
        row_attrs.delete(k)
      end
      # Convert location name to Location
      row_attrs[:location_id] = Location.find_by(:name => row_attrs["location"]).id
      # If location is not remote, don't save address to DB
      if Location.where(kind: "Office").map(&:name).include?(row_attrs["location"])
        ["home_address_1", "home_address_2", "home_city", "home_state", "home_zip"].each do |k|
          row_attrs.delete(k)
        end
      end
      # Remove location keys
      ["location", "location_type", "country"].each do |k|
        row_attrs.delete(k)
      end
      # Convert dates
      row_attrs["hire_date"] = DateTime.strptime(row_attrs["hire_date"], "%m/%d/%y")
      row_attrs["leave_start_date"] = DateTime.strptime(row_attrs["leave_start_date"], "%m/%d/%y") if row_attrs["leave_start_date"]
      # add sAMAccountName
      row_attrs["sam_account_name"] = row_attrs["email"].partition("@").first if row_attrs["email"]
      e.update_attributes(row_attrs)

      # Update the worker info in AD
      if e.valid? && e.email.present?
        ldap_entry = ads.find_entry("mail", e.email).first
        if ldap_entry
          attrs = ads.updatable_attrs(e, ldap_entry)
          attrs.delete(:mobile) # Not currently saving this information for any workers until Workday mobile export is ironed out
          blank_attrs, populated_attrs = attrs.partition { |k,v| v.blank? }

          ads.delete_attrs(e, ldap_entry, blank_attrs)
          ads.replace_attrs(e, ldap_entry, populated_attrs)
        else
          errors["#{e.email}, #{e.first_name}, #{e.last_name}"] = { "Active Directory Error" => "User not found in Active Directory. Update failed." }
        end
      else
        errors["#{e.email}, #{e.first_name}, #{e.last_name}"] = e.email.present? ? e.errors.messages : { "Active Directory Error" => "No email to match to AD records" }
      end
    end
    TechTableMailer.alert_email(JSON.pretty_generate(errors)).deliver_now if errors.present?
  end
end
