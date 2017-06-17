class OffboardingService

  def offboard(employees)
    processed_offboards = []

    employees.each do |employee|
      processed_offboards << process(employee)
    end

    processed_offboards
  end

  def process(employee)
    results = {}

    # transfer google apps
    google_apps_service = GoogleAppsService.new
    transfer = google_apps_service.process(employee)
    results['Google Apps'] = transfer

    # deactivate sql services
    sql_service = SqlService.new
    deactivations = sql_service.deactivate_all(employee)

    results = results.merge(deactivations)

    # TechTableMailer.offboard_status(employee).deliver_now
    results
  end


end

# computerclub@opentable.computercl

# mezzo offboarding status subject line
