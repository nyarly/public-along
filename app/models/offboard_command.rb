class OffboardCommand
  include ActiveModel::Model

  validates :employee_id,
            presence: true

  attr_accessor :employee_id
  attr_reader :employee_email, :employee_name, :ot_id, :forward_email, :forward_google

  def initialize(employee_id)
    @employee ||= Employee.find_by(employee_id: employee_id)
  end

  def employee_email
    @employee.email
  end

  def employee_name
    @employee.cn
  end

  def ot_id
    employee_email[/[^@]+/]
  end

  def forward_google
    if @employee.offboarding_infos.present? && offboarding_info.transfer_google_docs_id
        Employee.find(offboarding_info.transfer_google_docs_id).email
    else
      manager_email
    end
  end

  def forward_email
    if @employee.offboarding_infos.present?
      Employee.find(offboarding_info.forward_email_id).email
    else
      manager_email
    end
  end

  def manager_email
    Employee.find_by(employee_id: @employee.manager_id).email
  end

  def offboarding_info
    @employee.offboarding_infos.order("created_at").last
  end

end
