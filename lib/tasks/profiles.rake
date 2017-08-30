namespace :profiles do
  desc "one time population of employee data to employee profile"
  task :initial_population => :environment do
    employees = Employee.all
    puts "Creating initial profiles for #{employees.count} employee records"

    ActiveRecord::Base.transaction do
      employees.find_each do |employee|
        if employee.contract_end_date.present?
          end_date = employee.contract_end_date
        elsif employee.termination_date.present?
          end_date = employee.termination_date
        else
          end_date = nil
        end

        if employee.status == "Inactive"
          profile_status = "Leave"
        else
          profile_status = employee.status
        end

        employee.profiles.build(
          profile_status: profile_status,
          start_date: employee.hire_date,
          end_date: end_date,
          manager_id: employee.del_manager_id,
          department_id: employee.del_department_id,
          worker_type_id: employee.del_worker_type_id,
          location_id: employee.del_location_id,
          job_title_id: employee.del_job_title_id,
          company: employee.del_company,
          adp_assoc_oid: employee.del_adp_assoc_oid,
          adp_employee_id: employee.del_employee_id
        )

        if employee.save!
          puts "#{employee.first_name} #{employee.last_name} account updated"
        else
          puts "#{employee.first_name} #{employee.last_name} account failed"
        end
      end
    end

    puts "Completed"
  end
end
