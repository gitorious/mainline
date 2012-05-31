require "net/ldap"
class LdapGroup < ActiveRecord::Base
  extend GroupBehavior

#  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
  has_many(:repositories, :as => :owner, :conditions => ["kind NOT IN (?)",
                                                         Repository::KINDS_INTERNAL_REPO],
           :dependent => :destroy)

  has_many :projects, :as => :owner
  has_many :committerships, :as => :committer, :dependent => :destroy

  
  Paperclip.interpolates('group_name'){|attachment,style| attachment.instance.name}

  avatar_local_path = '/system/group_avatars/:group_name/:style/:basename.:extension'
  has_attached_file :avatar,
    :default_url  =>'/images/default_group_avatar.png',
    :styles => { :normal => "300x300>", :medium => "64x64>", :thumb => '32x32>', :icon => '16x16>' },
    :url => avatar_local_path,
    :path => ":rails_root/public#{avatar_local_path}"


  serialize :member_dns

  def ldap_group_names
    member_dns.join("\n")
  end

  def ldap_group_names=(newline_separated_list)
    self.member_dns = newline_separated_list.split("\n")
  end
  
  def members
    []
  end
  
  def to_param
    name
  end

  def breadcrumb_parent
    nil
  end
  
  def title
    name
  end

  def user_role(candidate)
    if candidate == creator
      Role.admin
    end
  end

  def self.ldap_configurator
    auth_configuration_path = File.join(Rails.root, "config", "authentication.yml")
    configuration = YAML::load_file(auth_configuration_path)[RAILS_ENV]["methods"].detect do |m|
      m["adapter"] == "Gitorious::Authentication::LDAPAuthentication"
    end
    raise LdapConnection::LdapError, "No LDAP configuration found for current environment (#{Rails.env}) in #{auth_configuration_path}" unless configuration
    Gitorious::Authentication::LDAPConfigurator.new(configuration)
  end

  def self.ldap_groups_for_user(user)
    configurator = ldap_configurator
    membership_attribute = ldap_configurator.membership_attribute_name
    LdapConnection.new({:host => configurator.server, :port => configurator.port, :encryption => configurator.encryption}).bind_as(configurator.bind_username, configurator.bind_password) do |connection|
      entries = connection.search(
        :base => configurator.base_dn,
        :filter => Net::LDAP::Filter.eq(configurator.login_attribute, user.login),
        :attributes => [membership_attribute])
      if !entries.blank?
        return entries.first[membership_attribute]
      end
    end
  end

  
end

class LdapConnection
  attr_reader :options
  
  def initialize(options)
    @options = options
  end

  def bind_as(bind_user_dn, bind_user_pass)
    connection = Net::LDAP.new({:host => options[:host], :port => options[:port], :encryption => options[:encryption]})
    connection.auth(bind_user_dn, bind_user_pass)
    begin
      if connection.bind
        yield BoundConnection.new(connection)
        connection.close
      end
    rescue Net::LDAP::LdapError => e
      raise LdapError, "Unable to connect to the LDAP server on #{options[:host]}:#{options[:port]}. Are you sure the LDAP server is running?"
    end
  end

  class BoundConnection
    def initialize(native_connection)
      @native_connection = native_connection
    end

    def search(options)
      @native_connection.search(options)
    end
  end

  class LdapError < StandardError;end
end
