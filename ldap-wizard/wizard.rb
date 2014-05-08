require "pathname"

WIZARD_ROOT = File.dirname(__FILE__)
RAILS_ROOT = Pathname(WIZARD_ROOT + "/../")
ENV["BUNDLE_GEMFILE"] = (RAILS_ROOT + "Gemfile").to_s

$LOAD_PATH << WIZARD_ROOT + "/lib"
$LOAD_PATH << (RAILS_ROOT + "lib").to_s
$LOAD_PATH << (RAILS_ROOT + "app").to_s

require "bundler"
Bundler.setup(:default, :ldap_wizard)

require "net/ldap"

# Out libs
require "credentials"
require "ldap_configuration_presenter"
require "ldap_tester"
require "gitorious/configuration_reader"
require "auth_config_loader"

require "sinatra"
require "sinatra/reloader"
require "yaml"
require "gitorious/authentication"
require "gitorious/authentication/ldap_configurator"
require "gitorious/authentication/ldap_authentication"
require "makeup/markup"

set :run, true
set :port, 1337
set :bind, '0.0.0.0'

class ConfigurationError < StandardError
end

get "/" do
  readme_file = Pathname(WIZARD_ROOT + "/README.md")
  @readme = Makeup::Markup.new.render("README.md", readme_file.read)
  erb :readme
end

get "/begin" do
  begin
    @configurator = AuthConfigLoader.load_auth_file
    @credentials = Credentials.new
    erb :wizard
  rescue ConfigurationError => e
    render_error e.message
  end
end

post "/test" do
  params["bind_user"] = {"username" => params[:bind_username], "password" => params[:bind_password]}
  configuration = Gitorious::Authentication::LDAPConfigurator.new(params)
  @configurator = LdapConfigurationPresenter.new(configuration)
  @credentials = Credentials.from_params(params)
  ldap_tester = LdapTester.new(configuration, @credentials)
  @test_results = ldap_tester.execute
  erb :wizard
end

# Curl'able interface. Do a HTTP POST with username and password parameters for a quick sanity check
post "/check" do
  configurator = AuthConfigLoader.load_auth_file.config
  credentials = Credentials.from_params(params)
  tester = LdapTester.new(configurator, credentials)
  if tester.success?
    status 200
    body "Authentication succeeded"
  else
    status 403
    body "Authentication failed"
  end
end

helpers do
  def field(obj, name, description, help_text=nil, options=nil)
    value = obj.public_send(name.to_sym)
    result = "<div class=\"control-group\">"
    result << "<label class=\"control-label\">#{description}</label>\n"
    result << "<div class=\"controls\">"
    if options
      result << select_field(name, value.to_s, options)
    else
      result << text_field(name, value)
    end
    result << "</div>"
    result << "<span class=\"help-block\">#{help_text}</span>" if help_text
    result << "</div>"
    result
  end

  def text_field(name, value)
    field_type = (name == :password) ? "password" : "text"
    "<input type =\"#{field_type}\" name=\"#{name}\" value=\"#{value}\">"
  end

  def select_field(name, value, options)
    result = "<select name=\"#{name}\">"
    options.each do |option|
      selected = (option == value) ? " selected" : ""
      result << "<option value=\"#{option}\" #{selected}>#{option}</option>"
    end
    result << "</select>"
  end
end





def render_error(message)
  @error = message
  erb :readme
end
