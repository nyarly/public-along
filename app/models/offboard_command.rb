class OffboardCommand
  include ActiveModel::Model  

  attr_accessor :employee_id

  validates :employee_id,
            presence: true

  def employee
    Employee.find(self.employee_id)
  end

  def ot_id
    employee.email[/[^@]+/]
  end

  def forward_email
    if offboarding_info.present?
      Employee.find(offboarding_info.forward_email_id).email
    else
      Employee.find(employee.manager_id).email
    end
  end

  def offboarding_info
    OffboardingInfo.order("created_at").last
  end

end
