class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      user.update_attributes(role_name: roles(user))
    end
  end

  protected

  def roles(user)
    roles = []
    if memberships(user).include?("CN=mezzo_access_admin,OU=OT,DC=ottest,DC=opentable,DC=com")
      roles << "Admin"
    end
    if memberships(user).include?("CN=mezzo_access_hr,OU=OT,DC=ottest,DC=opentable,DC=com")
      roles << "HumanResources"
    end
    if memberships(user).include?("CN=mezzo_access_manager,OU=OT,DC=ottest,DC=opentable,DC=com")
      roles << "Manager"
    end
    if memberships(user).include?("CN=mezzo_access_helpdesk,OU=OT,DC=ottest,DC=opentable,DC=com")
      roles << "Helpdesk"
    end
    if roles.blank?
      roles << "Basic"
    end
    roles
  end

  def memberships(user)
    Devise::LDAP::Adapter.get_ldap_param(user.ldap_user,"memberof")
  end
end
