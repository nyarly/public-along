class OffboardingService
  APPLICATIONS = ["Google Apps", "Office 365", "OTA", "CHARM EU", "CHARM JP", "CHARM NA", "ROMS"]

  def initialize(employees)
    processed_offboards = []

    employees.each do |employee|
      EmpAccessLevelService.new(employee)
      emp_access_levels = employee.emp_access_levels
      processed_offboards << process(emp_access_levels, employee)
    end

    processed_offboards
  end

  private

  def process(emp_access_levels, employee)
    processed_emp_als = []

    emp_access_levels.each do |emp_access_level|
      application = Application.find(emp_access_level.access_level.application_id)

      # this doesn't do anything now
      # once the services are complete, it should change the
      # emp_access_level.active to false if the service succeeds in offboarding

      if application.name == "Google Apps"
        # call google app service with info
      elsif application.name == "Office 365"
        # call office 365 service with info
      elsif application.name.include? == "CHARM"
        # call charm service
      elsif application.name == "ROMS"
        # call ROMS service
      elsif application.name == "OTA"
        # call OTA service
      end

      emp_access_level.save!
      processed_emp_als << emp_access_level
    end

    send_notification(employee)
    processed_emp_als
  end

  def send_notification(employee)
    TechTableMailer.offboard_status(employee).deliver_now
  end

end
