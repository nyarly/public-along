class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :trackable
  serialize :role_names

  def roles
    @roles ||= Role.list(self)
  end

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }
  validates :ldap_user,
            presence: true,
            uniqueness: { case_sensitive: false }
  validates :adp_employee_id,
            presence: true,
            uniqueness: true

  # users have an employee record
  belongs_to :employee

  def ldap_before_save
    self.email = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"mail").first
    self.first_name = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"givenName").first
    self.last_name = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"sn").first
    self.adp_employee_id = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"employeeID").first
    self.employee_id = Employee.find_by_employee_id(self.adp_employee_id).id
  end

  def full_name
    self.first_name + " " + self.last_name
  end

  def is_manager?
    self.employee.direct_reports.count > 0
  end

  # user is a manager + another role
  def has_dual_manager_role?
    self.roles.count > 1 && self.roles.include?("Manager")
  end
end
