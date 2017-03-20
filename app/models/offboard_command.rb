class OffboardCommand
  include ActiveModel::Model

  validates :employee_id,
            presence: true

  attr_accessor :employee_id
  attr_reader :employee_email, :employee_name, :ot_id, :forward_email

  def employee
    @employee = Employee.find(self.employee_id)
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

  def forward_email
    get_forwarding_email
  end

  def get_forwarding_email
    if @employee.offboarding_infos.present?
      offboarding_info = @employee.offboarding_infos.order("created_at").last
      forward_email_id = offboarding_info.forward_email_id
      Employee.find(forward_email_id).email
    else
      Employee.find(@employee.manager_id).email
    end
  end

end
