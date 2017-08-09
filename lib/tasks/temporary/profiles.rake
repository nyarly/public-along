namespace :profiles do
  desc "move data from employee model to profile model"
  task :populate_from_employee => :environment do
    employees = Employee.all
    puts "Updating #{employees.count} employee records"

    ActiveRecord::Base.transaction do
      adp    = AdpService::Base.new
      parser = WorkerJsonParser.new

      employees.each do |employee|

        json            = adp.worker("/#{employee.adp_assoc_oid}")
        worker_json     = json["workers"][0]
        work_assignment = parser.find_work_assignment(worker_json)
        end_date        = work_assignment["terminationDate"].present? ? work_assignment["terminationDate"] : parser.find_worker_end_date(worker_json)
        dept_str        = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Department"}
        biz_unit        = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Business Unit"}

        employee.profiles.build(
          status: employee.status,
          start_date: work_assignment["actualStartDate"],
          end_date: end_date,
          manager_id: manager_id = work_assignment.dig("reportsTo",0,"workerID","idValue"),
          department_id: parser.find_dept(dept_str).id,
          worker_type_id: parser.find_worker_type(work_assignment).id,
          location_id: parser.find_location(work_assignment["homeWorkLocation"]).id,
          job_title_id: parser.find_job_title(work_assignment["jobCode"]).id,
          company: parser.find_biz_unit(biz_unit),
          adp_assoc_oid: worker_json["associateOID"],
          adp_employee_id: worker_json["workerID"]["idValue"].downcase
        )

        employee.hire_date = worker_json["person"]["workerDates"]["originalHireDate"]

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
