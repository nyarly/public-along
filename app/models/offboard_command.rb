class OffboardCommand
  include ActiveModel::Model

  validates :employee_id,
            presence: true

  attr_accessor :employee_id
  attr_reader :employee_email,
              :employee_name,
              :sam_account_name,
              :forward_email,
              :forward_google

  def initialize(employee_id)
    @employee ||= Employee.find_by(employee_id: employee_id)
    @manager = Employee.find_by(employee_id: @employee.manager_id)

  end

  def employee_email
    @employee.email
  end

  def employee_name
    @employee.cn
  end

  def sam_account_name
    @employee.sam_account_name
  end

  def archive_data
    if @employee.offboarding_infos.present? && offboarding_infos.archive_data
      offboarding_info.archive_data
    else
      'no info provided'
    end
  end

  def forward_google
    if @employee.offboarding_infos.present? && offboarding_info.transfer_google_docs_id
      Employee.find(offboarding_info.transfer_google_docs_id)
    else
      @manager
    end
  end

  def forward_email
    if @employee.offboarding_infos.present? && offboarding_infos.forward_email_id
      Employee.find(offboarding_info.forward_email_id)
    else
      @manager
    end
  end

  def reassign_salesforce
    if @employee.offboarding_infos.present? && offboarding_infos.transfer_google_docs_id
      Employee.find(offboarding_info.transfer_google_docs_id)
    else
      @manager
    end
  end

  def offboarding_info
    @employee.offboarding_infos.order("created_at").last
  end

end
