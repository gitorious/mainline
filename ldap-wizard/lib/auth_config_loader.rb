class AuthConfigLoader
  RAILS_ENV = ENV["RAILS_ENV"] || "development"

  def self.load_auth_file
    auth_file = RAILS_ROOT + "config/authentication.yml"
    raise ConfigurationError, "No config/authentication found" unless auth_file.exist?

    auth_config = YAML::load_file(auth_file) || {}
    auth_config = auth_config[RAILS_ENV] if auth_config.key?(RAILS_ENV)
    raise ConfigurationError, "No authentication configuration found in authentication.yml. #{auth_config.inspect}" unless auth_config
    raise ConfigurationError, "No authentication methods defined in authentication.yml. #{auth_config.inspect}" unless auth_config.key?("methods")

    methods = auth_config["methods"]
    raise ConfigurationError, "No adapters specified" unless methods

    ldap_config = auth_config["methods"].detect { |m| m["adapter"] == "Gitorious::Authentication::LDAPAuthentication" }
    raise ConfigurationError, "LDAP has not been configured in authentication.yml" unless ldap_config

    configurator = Gitorious::Authentication::LDAPConfigurator.new(ldap_config)
    LdapConfigurationPresenter.from_config(configurator)
  end
end
