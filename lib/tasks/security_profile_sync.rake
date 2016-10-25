require 'csv'

namespace :sec_prof do
  desc "initial security profile info sync from csv, ex rake sec_prof:csv['/this/path']"
  task :csv => :environment do
    sp_csv_text = File.read('lib/assets/sec_profs.csv')
    app_csv_text = File.read('lib/assets/applications.csv')
    al_csv_text = File.read('lib/assets/access_levels.csv')

    sp_csv = CSV.parse(sp_csv_text, :headers => true)
    app_csv = CSV.parse(app_csv_text, :headers => true)
    al_csv = CSV.parse(al_csv_text, :headers => true)

    sp_csv.each do |row|
      row_attrs = row.to_hash
      unless row_attrs["departments"].blank?
        sp = SecurityProfile.find_or_create_by(name: row_attrs["name"])

        # Convert department names to Departments
        depts = []
        dept_names = row_attrs["departments"].split(/\s*,\s*/)
        dept_names.each do |name|
          if name == "All"
            Department.find_each { |dept| sp.departments << dept unless sp.departments.include?(dept) }
          else
            depts << Department.find_by(name: name)
          end
        end

        # Associate Departments to Security Profile
        depts.each do |dept|
          sp.departments << dept unless sp.departments.include?(dept)
        end unless dept_names.include?("All")

        # Remove departments key
        row_attrs.delete("departments")

        sp.update_attributes(row_attrs)
      end
    end

    app_csv.each do |row|
      row_attrs = row.to_hash

      app = Application.find_or_create_by(name: row_attrs["name"])
      app.update_attributes(row_attrs)
    end

    al_csv.each do |row|
      row_attrs = row.to_hash
      unless row_attrs["security_groups"].blank?
        # Convert security_groups names to SecurityProfiles
        sec_profs = []
        sp_names = row_attrs["security_groups"].split(/\s*,\s*/)
        sp_names.each do |name|
          sec_profs << SecurityProfile.find_by(name: name)
        end

        # Convert application name to Application
        row_attrs["application_id"] = Application.find_by(name: row_attrs["application"]).id

        # Remove application and security_groups key
        ["application", "security_groups"].each do |k|
          row_attrs.delete(k)
        end

        # Create AccessLevel
        al = AccessLevel.find_or_create_by({name: row_attrs["name"], application_id: row_attrs["application_id"]})
        al.update_attributes(row_attrs)

        # Add AccessLevel to Security Profiles
        sec_profs.each do |sp|
          sp.access_levels << al unless sp.access_levels.include?(al)
        end
      end
    end
  end
end
