module EmployeeService
  class GrantBasicSecProfile < Base
    def process!
      begin
        security_profile = security_group_for_worker_type
        MezzoTransactionService.new(@employee.id, security_profile.id).process!
      rescue => e
        Rails.logger.info e
      end
      @employee.security_profiles
    end

    private

    def security_group_for_worker_type
      case @employee.worker_type.kind
      when "Regular"
        SecurityProfile.find_by(name: "Basic Regular Worker Profile")
      when "Temporary"
        SecurityProfile.find_by(name: "Basic Temp Worker Profile")
      when "Contractor"
        SecurityProfile.find_by(name: "Basic Contract Worker Profile")
      end
    end
  end
end
