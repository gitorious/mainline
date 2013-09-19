class LdapConfigurationPresenter
  attr_reader :config

  def self.from_config(config)
    new(config)
  end

  def initialize(config)
    @config = config
  end

  def login_attribute
    @config.login_attribute
  end

  def host
    @config.server
  end

  def base_dn
    @config.base_dn
  end

  def encryption
    @config.encryption
  end

  def port
    @config.port
  end

  def bind_username
    @config.bind_username
  end

  def bind_password
    @config.bind_password
  end

  def to_yaml
    result = {}
    ldap_conf = {
      "adapter" => "Gitorious::Authentication::LDAPAuthentication",
      "host" => host,
      "port" => port,
      "base_dn" => base_dn,
      "login_attribute" => login_attribute,
      #        "attribute_mapping" => attribute_mapping,
      "encryption" => encryption
    }
    ldap_conf["bind_user"] = {"username" => bind_username, "password" => bind_password} unless bind_username.blank?
    config = {
      "methods" =>
      [
        ldap_conf
      ]
    }
    result[RAILS_ENV]= config
    result.to_yaml
  end
end
