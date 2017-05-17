class OffboardingService

  def initialize(employees)
    processed_offboards = []

    employees.each do |employee|
      EmpAccessLevelService.new(employee)
      processed_offboards << process(employee)
    end

    processed_offboards
  end

  private

  def process(employee)
    processed_applications = []

    employee.emp_access_levels.each do |emp_access_level|

      if emp_access_level.active
        application = emp_access_level.access_level.application

        # this doesn't do anything now
        # once the services are complete, it should change the
        # emp_access_level.active to false if the service succeeds in offboarding

        if application.name == "Google Apps"
          # call google app service with info
        elsif application.name == "Office 365"
          # call office 365 service with info
        elsif application.name.include? "CHARM"
          # call charm service
        elsif application.name == "ROMS"
          # call ROMS service
        elsif application.name == "OTA"
          # call OTA service
        end

        emp_access_level.save!
        processed_applications << emp_access_level
      end
    end

    send_notification(employee)
    processed_applications
  end

  def send_notification(employee)
    TechTableMailer.offboard_status(employee).deliver_now
  end

end
