require 'i18n'

module ActiveDirectoryManager
  class LdapConnection
    attr_accessor :ldap, :errors

    def initialize
      @ldap ||= begin
        l = Net::LDAP.new
        l.host = SECRETS.ad_host
        l.port = 636
        l.encryption(method: :simple_tls)
        l.auth(SECRETS.ad_svc_user, SECRETS.ad_svc_user_passwd)
        l.bind
        l
      end
      @errors = {}
    end

    def find_entry(attr, value)
      ldap.search(
        :base => SECRETS.ad_ou_base,
        :filter => Net::LDAP::Filter.eq(attr, value)
      ) do |entry|
        entry
      end
    end
  end
end
