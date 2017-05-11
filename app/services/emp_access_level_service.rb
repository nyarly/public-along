class EmpAccessLevelService

  def initialize(employee)
    @employee = employee
    @security_profiles = @employee.active_security_profiles
    @access_levels = access_levels
    process
  end

  private

  def process
    emp_access_levels = []

    @access_levels.each do |access_level|
      eal = EmpAccessLevel.find_or_create_by(
        employee: @employee,
        access_level: access_level,
        active: true
      )
      eal.save!
      emp_access_levels << eal
    end

    emp_access_levels
  end

  def access_levels
    access_levels = []
    @security_profiles.each do |sp|
      sp.access_levels.each do |al|
        access_levels << al
      end
    end
    access_levels
  end

end
