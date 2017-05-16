namespace :emp_access_level do
  desc "create emp access levels for existing employees with security profiles"
  task :create => :environment do

    Employees.find_each do |e|
      e.active_security_profiles.each do |sp|
        sp.access_levels.each do |al|
          EmpAccessLevel.create(
            access_level_id: al.id,
            employee_id: e.id,
            active: true
          )
        end
      end
    end
  end
end
