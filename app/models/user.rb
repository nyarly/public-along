class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :trackable

  def role
    @role ||= Role.for(self)
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
            uniqueness: true

  def ldap_before_save
    self.email = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"mail").first
    self.first_name = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"givenName").first
    self.last_name = Devise::LDAP::Adapter.get_ldap_param(self.ldap_user,"sn").first
  end
end
