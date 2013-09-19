class AuthConfigLoader

  def self.load_auth_file
    auth_file = RAILS_ROOT + "config/authentication.yml"
    raise ConfigurationError, "No config/authentication found" unless auth_file.exist?
    global_auth_config = YAML::load_file(auth_file)
    auth_config = global_auth_config[RAILS_ENV]
    raise ConfigurationError, "No authentication methods specified for #{RAILS_ENV}. #{global_auth_config.inspect}" unless auth_config
    raise ConfigurationError, "No methods defined" unless auth_config.key?("methods")
    methods = auth_config["methods"]
    raise ConfigurationError, "No adapters specified" unless methods
    ldap_config = auth_config["methods"].select {|m| m["adapter"] == "Gitorious::Authentication::LDAPAuthentication"}
    raise ConfigurationError, "LDAP has not been configured in authentication.yml" unless ldap_config
    _c = Gitorious::Authentication::LDAPConfigurator.new(ldap_config.first)
    LdapConfigurationPresenter.from_config(_c)
  end
end
