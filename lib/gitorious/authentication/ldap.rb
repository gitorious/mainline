# encoding: utf-8
#--
#   Copyright (C) 2009 Marius Mathiesen <marius@shortcut.no>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'net/ldap'
module Gitorious
  module Authentication
    class Ldap
      attr_accessor :logger
      
      def initialize(config)
        @logger = ::Rails.logger if !@logger && defined?(::Rails) && Rails.respond_to?(:logger)
        @logger = RAILS_DEFAULT_LOGGER if !@logger && defined?(RAILS_DEFAULT_LOGGER)
        @logger = Logger.new(STDOUT) if !@logger

        @host = config["host"]
        raise '\'host\' is required when performing LDAP authentication' unless @host
        @autoregistration = config["autoregistration"]
        @port = config["port"] || 389
        @bind_method = (config["bind_method"] || "simple").to_sym
        @bind_username = config["bind_username"]
        @bind_password = config["bind_password"]
        @base_dn = config["base_dn"]
        raise '\'base_dn\' is required when performing LDAP authentication' unless @base_dn
        @username_attribute = config["username_attribute"]
        raise '\'username_attribute\' is required when performing LDAP authentication' unless @username_attribute
        @full_name_attribute = config["full_name_attribute"]
        @email_attribute = config["email_attribute"]
      end

      # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
      def authenticate(username,password)
        logger.warn "LDAP authenticating #{username}"
        if @bind_username.nil?
            return nil unless ldap_check_password?(username, password)
        else
            dn = get_dn_of_user(@email_attribute,username)
            dn ||= get_dn_of_user(@username_attribute,username)
            return nil unless dn
            return nil unless ldap_check_password?(dn, password)
        end
        u = User.find_by_login(username)
        if u
          return u
        else
          logger.warn "LDAP authentication succeeded for #{username} but no gitorious account exists"
          return auto_register(dn)
        end
      end
      
      # Automatically registers a user by their ldap DN.  Returns the user or nil.
      def auto_register(dn)
        logger.info "LDAP auto-registering dn #{dn}"
        user = User.new do |u|
            ldap = Net::LDAP.new :host => @host,
            :port => @port,
            :auth => {
                :method => @bind_method,
                :username => @bind_username,
                :password => @bind_password
            }
            filter = Net::LDAP::Filter.eq("objectClass", "user") & Net::LDAP::Filter.eq('DistinguishedName', dn)
            attrs = [@username_attribute]
            attrs << @full_name_attribute if @full_name_attribute
            attrs << @email_attribute if @email_attribute
            ldap.search( :base => @base_dn, :attributes => attrs, :filter => filter, :return_result => false, :size => 1 ) do |entry|
                u.email = entry[@email_attribute].first if @email_attribute && entry[@email_attribute]
                u.fullname = entry[@full_name_attribute].first if @full_name_attribute && entry[@full_name_attribute]
                u.login = entry[@username_attribute].first
            end
            u.crypted_password = 'ldap'
            u.salt = 'ldap'
            u.activated_at = Time.now.utc
            u.activation_code = nil
            u.terms_of_use = '1'
            u.aasm_state = 'terms_accepted'
        end
        user.save!
        user
      end

      def ldap_check_password?(username,password)
        ldap = Net::LDAP.new :host => @host,
        :port => @port,
        :auth => {
            :method => @bind_method,
            :username => username,
            :password => password
        }
        ldap.bind
      end
      
      # return the dn of the user that has an attribute named search_attribute with a value of seach_value, or nil if not found
      def get_dn_of_user(search_attribute,search_value)
        logger.warn "get_dn_of_user(#{search_attribute},#{search_value})"
        ldap = Net::LDAP.new :host => @host,
        :port => @port,
        :auth => {
            :method => @bind_method,
            :username => @bind_username,
            :password => @bind_password
        }
        filter = Net::LDAP::Filter.eq("objectClass", "user") & Net::LDAP::Filter.eq(search_attribute, search_value)
        ldap.search( :base => @base_dn, :filter => filter, :return_result => false, :size => 1 ) do |entry|
           return entry.dn
        end
        nil
      end

    end
  end
end

