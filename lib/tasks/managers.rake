namespace :managers do
  desc "one time population of manager pk into employee table"
  task :populate_direct_reports => :environment do
    employees = Employee.all

    ActiveRecord::Base.transaction do
      employees.find_each do |employee|
        if employee.profiles.count >= 1 && employee.current_profile.present? && employee.current_profile.manager_adp_employee_id.present?
          manager = Employee.find_by_employee_id(employee.current_profile.manager_adp_employee_id)
          if manager.present?
            employee.assign_attributes(manager_id: manager.id)
            employee.save!
          end
        elsif employee.current_profile.blank?
          puts "#{employee.cn} #{employee.id} needs current proifle"
        end
      end
    end
  end

  desc "one time population of employee pk into users table"
  task :populate_user_employee => :environment do
    users = User.all

    ActiveRecord::Base.transaction do
      users.find_each do |user|
        employee = Employee.find_by_employee_id(user.adp_employee_id)
        if employee.present?
          user.employee_id = employee.id
          user.save!
        else
          puts user.inspect
        end
      end
    end
  end
end
