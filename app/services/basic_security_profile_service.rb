class BasicSecurityProfileService
  def initialize(employee)
    @employee = employee
    @worker_type_security_profile = security_group_for_worker_type
  end

  def process!
    begin
      MezzoTransactionService.new(@employee.id, @worker_type_security_profile.id).process!
    rescue => e
      Rails.logger.info e
    end
    @employee.security_profiles
  end

  private

  def security_group_for_worker_type
    case @employee.worker_type.name
    when "Regular"
      SecurityProfile.find_by(name: "Basic Regular Worker Profile")
    when "Temporary"
      SecurityProfile.find_by(name: "Basic Temp Worker Profile")
    when "Contractor"
      SecurityProfile.find_by(name: "Basic Contract Worker Profile")
    end
  end
end
