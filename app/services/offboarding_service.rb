class OffboardingService
  APPLICATIONS = ["Google Apps", "Office 365", "OTA", "CHARM EU", "CHARM JP", "CHARM NA", "ROMS"]

  def initialize(employees)
    processed_offboards = []

    employees.each do |employee|
      emp_access_levels = EmpAccessLevelService.new(employee)
      processed_offboards << process(emp_access_levels, employee)
    end

    processed_offboards
  end

  private

  def process(emp_access_levels, employee)
    offboarding_info = @employee.offboarding_infos.last
    processed_eal = []

    emp_access_levels.each do |emp_access_level|

      # this doesn't do anything now
      # once the services are complete, it should change the
      # emp_access_level.active to false if the service succeeds in offboarding

      if emp_access_level.name == "Google Apps"
        # call google app service with info
      elsif emp_access_level.name == "Office 365"
        # call office 365 service with info
      elsif emp_access_level.name.include? == "CHARM"
        # call charm service
      elsif emp_access_level.name == "ROMS"
        # call ROMS service
      elsif emp_access_level.name == "OTA"
        # call OTA service
      end

      emp_access_level.save!
      processed_eal << emp_acecss_level
    end unless emp_access_level.blank?

    send_notification(processed_eal, employee)
    processed_eal
  end

  def offboarding_info
    @employee.offboarding_infos.last || default_offboarding_info
  end

  def send_notification(eals, employee)
    TechTableMailer.offboard_status(eals, employee).deliver_now
  end

end
