class OffboardingService

  attr_accessor :results

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
    results['Google Apps'] = "completed"

    # deactivate sql services
    sql_service = SqlService.new
    deactivations = sql_service.deactivate_all(employee)

    # merge results hashes
    results = results.merge(deactivations)

    TechTableMailer.offboard_status(employee, results).deliver_now
    results
  end

end
