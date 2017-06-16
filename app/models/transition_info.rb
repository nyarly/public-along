module TransitionInfo

  def initialize(employee_id)
    @employee ||= Employee.find_by(employee_id: employee_id)
  end

  class Offboard
    include TransitionInfo

    attr_accessor :archive_data,
                  :forward_email,
                  :forward_google,
                  :offboard_info,
                  :offboard_notes,
                  :reassign_salesforce

    def offboarding_info
      OffboardingInfo.where(employee_id: @employee.id).order("created_at").last
    end

    def archive_data
      if offboarding_info.present? && offboarding_info.archive_data
        offboarding_info.archive_data
      else
        'no info provided'
      end
    end

    def forward_email
      if offboarding_info.present? && offboarding_info.forward_email_id
        Employee.find(offboarding_info.forward_email_id).email
      else
        @employee.manager.email
      end
    end

    def forward_google
      if offboarding_info.present? && offboarding_info.transfer_google_docs_id
        Employee.find(offboarding_info.transfer_google_docs_id).email
      else
        @employee.manager.email
      end
    end

    def offboard_notes
      offboard_info.emp_transaction.notes
    end

    def reassign_salesforce
      if offboarding_info.present? && offboarding_info.reassign_salesforce_id
        Employee.find(offboarding_info.reassign_salesforce_id).email
      else
        @employee.manager.email
      end
    end
  end

end
