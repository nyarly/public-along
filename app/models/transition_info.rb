module TransitionInfo

  def initialize(employee_id)
    @employee ||= Employee.find_by_employee_id(employee_id)
  end

  class Offboard
    include TransitionInfo

    def offboarding_info
      @employee.offboarding_infos.order("created_at").last
    end

    def emp_transaction
      if offboarding_info.present?
        EmpTransaction.find(offboarding_info.emp_transaction_id)
      end
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

  class Onboard
    include TransitionInfo

    def onboarding_info
      @employee.onboarding_infos.order("created_at").last
    end

    def emp_transaction
      if onboarding_info.present?
        EmpTransaction.find(onboarding_info.emp_transaction_id)
      end
    end
  end

end
