require 'net/ldap'

# LDAP authentication for User.rb
module LdapAuthentication
  
  def ldap_authenticated?(password)
    host = GitoriousConfig['ldap_host']
    return if host.blank?

    # todo: test SSL with real LDAP server
    encryption = GitoriousConfig['ldap_encryption']
    params = {}
    params[:encryption] = encryption.to_sym if encryption
    
    ldap = Net::LDAP.new(params)
    ldap.host = host
    ldap.port = GitoriousConfig['ldap_port']

    dn_template = GitoriousConfig['ldap_dn_template']
    return if dn_template.blank?

    username = self.login
    dn = eval('"' + dn_template + '"')

    # attempt to authenticate against the LDAP server
    ldap.auth(dn, password)
    ldap.bind
  end

end

