module Employee::CurrentProfile
  def current_profile
    # if employee data is not persisted, like when previewing employee data from an event
    # scope on profiles is not available, so must access by method last
    if self.persisted?
      if self.status == "active"
        @current_profile ||= self.profiles.active.last
      elsif self.status == "inactive"
        @current_profile ||= self.profiles.leave.last
      elsif self.status == "pending"
        @current_profile ||= self.profiles.pending.last
      elsif self.status == "terminated"
        @current_profile ||= self.profiles.terminated.last
      else
        self.profiles.last
      end
    else
      @current_profile ||= self.profiles.last
    end
  end

end
