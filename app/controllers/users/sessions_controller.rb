class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      user.update_attributes(role_names: ["Manager"])
    end
  end

  protected

  DN_MAPPING = {
    "Admin" => "CN=OTApplications-Mezzo-Admin,OU=Mezzo,OU=OT Applications,OU=Security Groups," + SECRETS.ad_ou_base,
    "HumanResources" => "CN=OTApplications-Mezzo-HR,OU=Mezzo,OU=OT Applications,OU=Security Groups," + SECRETS.ad_ou_base,
    "Manager" => "CN=OTApplications-Mezzo-Manager,OU=Mezzo,OU=OT Applications,OU=Security Groups," + SECRETS.ad_ou_base,
    "Helpdesk" => "CN=OTApplications-Mezzo-TechTable,OU=Mezzo,OU=OT Applications,OU=Security Groups," + SECRETS.ad_ou_base,
    "Security" => "CN=OTApplications-Mezzo-Security,OU=Mezzo,OU=OT Applications,OU=Security Groups," + SECRETS.ad_ou_base
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
