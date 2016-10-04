class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      user.update_attributes(role_names: roles(user))
    end
  end

  protected

  DN_MAPPING = {
    "Admin" => "CN=mezzo_access_admin,OU=OT,DC=ottest,DC=opentable,DC=com",
    "HumanResources" => "CN=mezzo_access_hr,OU=OT,DC=ottest,DC=opentable,DC=com",
    "Manager" => "CN=mezzo_access_manager,OU=OT,DC=ottest,DC=opentable,DC=com",
    "Helpdesk" => "CN=mezzo_access_helpdesk,OU=OT,DC=ottest,DC=opentable,DC=com"
  }

  def roles(user)
    roles = []
    DN_MAPPING.each do |k, v|
      if memberships(user).include?(v)
        roles << k
      end
    end
    roles
  end

  def memberships(user)
    Devise::LDAP::Adapter.get_ldap_param(user.ldap_user,"memberof")
  end
end
