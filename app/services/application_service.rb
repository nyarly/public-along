# Offboards worker from all automated services
class ApplicationService
  attr_reader :employee

  def initialize(employee)
    @employee = employee
    @results = results
  end

  def offboard_all_apps
    offboard_google
    offboard_sql
    send_results
  rescue StandardError => error
    Rails.logger.error "Offboard all apps failed with #{error}"
  end

  def results
    @results ||= {}
  end

  private

  # transfer google docs
  def offboard_google
    google_apps_service = GoogleAppsService.new
    transfer = google_apps_service.process(employee)
    results['Google Apps'] = transfer
  end

  # deactivate worker accounts in sql dbs
  def offboard_sql
    sql_service = SqlService.new
    deactivations = sql_service.deactivate_all(employee)
    results.reverse_merge!(deactivations)
  end

  def send_results
    TechTableMailer.offboard_status(employee, results).deliver_now
  end
end
