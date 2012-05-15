require "config/environment"
require "rubygems"
require "bundler"
Bundler.require("default", Rails.env)

# in: user DN
# out: member group names

USER_BIND_NAME = "cn=admin"
USER_BIND_PW = "omgomg"
HOST="localhost"
PORT=1389
MEMBERSHIP_ATTRIBUTE_NAME="ismemberof"
BASE_DN="dc=gitorious,dc=org" 

class LdapGroupLookup
  def initialize
    @connection = Net::LDAP.new({:host => HOST, :port => PORT})
  end
  
  def bind
    @connection.auth(USER_BIND_NAME, USER_BIND_PW)
    @connection.bind
  end
  
  def group_names(filter)
    raise "Connection error" unless bind
    Array(fetch_group_names(filter))
  end
  
  def fetch_group_names(user_filter)
    entries = @connection.search(:base => BASE_DN, :filter => user_filter, :attributes => [MEMBERSHIP_ATTRIBUTE_NAME])
    if !entries.blank?
      return entries.first[:ismemberof]
    end
  end
  
end

user_filter = Net::LDAP::Filter.eq("cn", ARGV[0])
puts LdapGroupLookup.new.group_names(user_filter)


