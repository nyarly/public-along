class OffboardingService

  def offboard(employees)
    processed_offboards = []

    employees.each do |employee|
      processed_offboards << process(employee)
    end

    processed_offboards
  end

  def process(employee)
    processed_applications = []

    Applications::AUTOMATED_OFFBOARDS.each do |service|
      if service.include? "Google"
        process_google_apps(employee)
      elsif service.include? "CHARM"

      elsif service.include? "OTA"

      elsif service.include? "ROMS"

      end
    end

    send_notification(employee)
    processed_applications
  end

  def process_google_apps(employee)
    google_apps = GoogleAppsService.new
    transfer = google_apps.transfer_data(employee)
    confirmation = google_apps.confirm_transfer(transfer.id)
    access_level = find_emp_access_level(employee, "Google Apps")

    if confirmation == "whatever"
      puts confirmation
      access_level.active = false
    else
      access_level.active = true
    end

    access_level.save!
    access_level
  end

  def process_sql_accounts(employee)
    sql_service = SqlService.new
    deactivations = sql_service.deactivate_all(employee)
    deactivations
  end

  def send_notification(employee)
    TechTableMailer.offboard_status(employee).deliver_now
  end

  def find_emp_access_level(employee, application)
    application = Application.where("name LIKE ?", application)
    access_level = AccessLevel.where("name LIKE ? AND application_id = ?", "Regular", application.id)

    emp_access_level = EmpAccessLevel.find_or_create_by(
      employee: employee,
      access_level: access_level
    )

    emp_access_level.save!
    emp_access_level
  end

end

computerclub@opentable.computercl

mezzo offboarding status subject line
