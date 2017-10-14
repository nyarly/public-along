class ManagerAccessService
  def initialize(employee)
    @employee = employee
    @manager_sec_profile = SecurityProfile.find_by(name: "Basic Manager")
  end

  def process!
    begin
      if needs_manager_permissions?
        MezzoTransactionService.new(@employee.id, @manager_sec_profile.id).process!
      end
    rescue => e
      Rails.logger.info e
    end
    @employee.security_profiles
  end

  private

  def needs_manager_permissions?
    return false if @employee.current_profile.management_position != true
    return false if @employee.security_profiles.include? @manager_sec_profile
    true
  end
end
