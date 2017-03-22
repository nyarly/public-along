class OffboardCommand
  include ActiveModel::Model

  validates :employee_id,
            presence: true

  attr_accessor :employee_id
  attr_reader :employee_email, :employee_name, :ot_id, :forward_email

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

  def forward_email
    if @employee.offboarding_infos.present?
      offboarding_info = @employee.offboarding_infos.order("created_at").last
      Employee.find(offboarding_info.forward_email_id).email
    else
      Employee.find_by(employee_id: @employee.manager_id).email
    end
  end

end
