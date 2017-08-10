namespace :restore_employees do
  task :populate_dev => :environment do
    employees = Employee.all

    ActiveRecord::Base.transaction do

      employees.each do |employee|

        employee.profiles.build(
          employee_id: employee.id,
          status: employee.status,
          start_date: employee.hire_date,
          end_date: employee.termination_date,
          manager_id: employee.manager_id,
          department_id: employee.department_id,
          worker_type_id: employee.worker_type_id,
          location_id: employee.location_id,
          job_title_id: employee.job_title_id,
          company: employee.company,
          adp_assoc_oid: employee.adp_assoc_oid,
          adp_employee_id: employee.employee_id
        )

        if employee.save!
          puts "#{employee.first_name} #{employee.last_name} account updated"
        else
          puts "#{employee.first_name} #{employee.last_name} account failed"
        end
      end
    end
  end


  desc "fix stuff"
  task :fix => :environment do
    employees = Employee.all

    ActiveRecord::Base.transaction do
      employees.each do |employee|
        employee.employee_id = employee.profiles.first.adp_employee_id
        employee.manager_id = employee.profiles.first.manager_id
        employee.department_id = employee.profiles.first.department_id
        employee.location_id = employee.profiles.first.location_id
        employee.company = employee.profiles.first.company
        employee.adp_assoc_oid = employee.profiles.first.adp_assoc_oid
        employee.worker_type_id = employee.profiles.first.worker_type_id
        employee.job_title_id = employee.profiles.first.job_title_id

        if employee.save!
          puts "restored"
        end
      end
    end
  end
end
