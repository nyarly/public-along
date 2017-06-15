class OffboardCommand
  include ActiveModel::Model

  validates :employee_id,
            presence: true

  attr_accessor :employee_id

  attr_reader :archive_data,
              :employee_email,
              :employee_name,
              :forward_email,
              :forward_google,
              :reassign_salesforce,
              :sam_account_name

  def initialize(employee_id)
    @employee ||= Employee.find_by(employee_id: employee_id)
  end

  def archive_data
    if offboarding_info.present? && offboarding_info.archive_data
      offboarding_info.archive_data
    else
      'no info provided'
    end
  end

  def employee_email
    @employee.email
  end

  def employee_name
    @employee.cn
  end

  def forward_email
    if offboarding_info.present? && offboarding_info.forward_email_id
      Employee.find(offboarding_info.forward_email_id).email
    else
      manager.email
    end
  end

  def forward_google
    if offboarding_info.present? && offboarding_info.transfer_google_docs_id
      Employee.find(offboarding_info.transfer_google_docs_id).email
    else
      manager.email
    end
  end

  def manager
    Employee.find_by(employee_id: @employee.manager_id)
  end

  def offboarding_info
    OffboardingInfo.where(employee_id: @employee.id).order("created_at").last
  end

  def reassign_salesforce
    if offboarding_info.present? && offboarding_info.reassign_salesforce_id
      Employee.find(offboarding_info.reassign_salesforce_id).email
    else
      manager.email
    end
  end

  def sam_account_name
    @employee.sam_account_name
  end
end
