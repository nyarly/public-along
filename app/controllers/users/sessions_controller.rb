class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      user.update_attributes(role_name: role_name(user))
    end
  end

  protected

  def role_name(user)
    case
    when memberships(user).include?("CN=mezzo_access_admin,OU=OT,DC=ottest,DC=opentable,DC=com")
      "Admin"
    when memberships(user).include?("CN=mezzo_access_hr,OU=OT,DC=ottest,DC=opentable,DC=com")
      "HumanResources"
    when memberships(user).include?("CN=mezzo_access_manager,OU=OT,DC=ottest,DC=opentable,DC=com")
      "Manager"
    when memberships(user).include?("CN=mezzo_access_helpdesk,OU=OT,DC=ottest,DC=opentable,DC=com")
      "Helpdesk"
    else
      "Basic"
    end
  end

  def memberships(user)
    Devise::LDAP::Adapter.get_ldap_param(user.ldap_user,"memberof")
  end
end
