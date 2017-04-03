class Email
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  TIMES = ["Now"]

  attribute :email_kind, String
  attribute :employee_id, String
  attribute :send_at, String

  attr_accessor :employee_id, :email_kind, :send_at

  def initialize(attributes={})
    self.email_kind = attributes[:email_kind]
    self.employee_id = attributes[:employee_id]
    self.send_at = attributes[:send_at]
  end

  def send_email
    if self.email_kind = "Onboarding"
      EmployeeWorker.perform_async(self.email_kind, self.employee_id)
  end

  def send_manager_permissions
    employee = Employee.find(@email.employee_id)
    manager = Employee.find_by(employee_id: employee.manager_id)
    ManagerMailer.permissions(manager, employee, @email.email_kind).deliver_now
  end

  def persisted?
    false
  end

end