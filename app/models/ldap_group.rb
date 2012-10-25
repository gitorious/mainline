# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "net/ldap"
require "finders/group_finder"
require "finders/ldap_group_finder"
class LdapGroup < ActiveRecord::Base
  extend GroupBehavior
  include GroupBehavior::InstanceMethods

  Paperclip.interpolates('group_name'){|attachment,style| attachment.instance.name}

  avatar_local_path = '/system/group_avatars/:group_name/:style/:basename.:extension'
  has_attached_file :avatar,
    :default_url  =>'/images/default_group_avatar.png',
    :styles => { :normal => "300x300>", :medium => "64x64>", :thumb => '32x32>', :icon => '16x16>' },
    :url => avatar_local_path,
    :path => ":rails_root/public#{avatar_local_path}"


  serialize :member_dns

  validate :validate_ldap_dns

  def validate_ldap_dns
    configurator = self.class.ldap_configurator
    Gitorious::Authorization::LDAP::Connection.new({
        :host => configurator.server,
        :port => configurator.port,
        :encryption => configurator.encryption}).bind_as(configurator.bind_username, configurator.bind_password) do |connection|
      Array(member_dns).each do |dn|
        if ldap_dn_in_base?(dn, configurator.group_search_dn)
          errors.add(:member_dns, "LDAP DN #{dn} is part of the LDAP search base #{configurator.group_search_dn}")
        end
        result = connection.search(
          :base => configurator.group_search_dn,
          :filter => generate_ldap_filters_from_dn(dn),
          :return_result => true)
        errors.add(:member_dns, "#{dn} not found") if result.empty?
      end
    end
  end

  # We don't want member DNs to contain the base DN to search
  def ldap_dn_in_base?(dn, base)
    dn =~ /#{base}/
  end

  def generate_ldap_filters_from_dn(dn)
    filters = dn.split(",").map do |pair|
      attribute, value = pair.split("=")
      Net::LDAP::Filter.eq(attribute, value)
    end
    filters.inject(filters.shift) do |memo, obj|
      memo & obj
    end
  end

  def ldap_group_names
    Array(member_dns).join("\n")
  end

  def ldap_group_names=(newline_separated_list)
    self.member_dns = newline_separated_list.split(/[\r\n]+/)
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

  def deletable?
    projects.empty?
  end

  def user_role(candidate)
    if candidate == creator
      Role.admin
    end
  end

  def self.ldap_configurator
    auth_configuration_path = File.join(Rails.root, "config", "authentication.yml")
    configuration = YAML::load_file(auth_configuration_path)[Rails.env]["methods"].detect do |m|
      m["adapter"] == "Gitorious::Authentication::LDAPAuthentication"
    end
    raise Gitorious::Authorization::LDAP::LdapError, "No LDAP configuration found for current environment (#{Rails.env}) in #{auth_configuration_path}" unless configuration
    Gitorious::Authentication::LDAPConfigurator.new(configuration)
  end

  def self.ldap_group_names_for_user(user)
    return [] unless user.is_a?(User)
    configurator = ldap_configurator
    membership_attribute = ldap_configurator.membership_attribute_name
    Gitorious::Authorization::LDAP::Connection.new({
        :host => configurator.server,
        :port => configurator.port,
        :encryption => configurator.encryption}).bind_as(configurator.bind_username, configurator.bind_password) do |connection|
      entries = connection.search(
        :base => configurator.base_dn,
        :filter => Net::LDAP::Filter.eq(configurator.login_attribute, configurator.reverse_username_transformation(user.login)),
        :attributes => [membership_attribute])
      if !entries.blank?
        return entries.first[membership_attribute]
      end
    end
  end

  def member?(user)
    self.class.groups_for_user(user).include?(self)
  end

  # Do an LDAP lookup for all member DNs in a given group
  def self.user_dns_in_group(group_name, member_attribute_name)
    cached_ldap_lookup(["ldap_group", "members", group_name]) do
      uncached_dns_in_group(group_name, member_attribute_name)
    end
  end

  def self.cached_ldap_lookup(key)
    expiry = ldap_configurator.cache_expiry
    Rails.cache.fetch(key, :expires_in => expiry.minutes) do
      yield
    end
  end


  def self.uncached_dns_in_group(group_name, member_attribute_name)
    configurator = ldap_configurator
    attribute, value = group_name.split("=")
    Gitorious::Authorization::LDAP::Connection.new({
        :host => configurator.server,
        :port => configurator.port,
        :encryption => configurator.encryption}).bind_as(configurator.bind_username, configurator.bind_password) do |connection|
      entries = connection.search(
        :base => configurator.group_search_dn,
        :filter => Net::LDAP::Filter.eq(attribute, value),
        :attributes => [member_attribute_name])
      if !entries.blank?
        return entries.first[member_attribute_name]
      end
    end
  end

  class MembershipsWrapper
    def initialize(members)
      @members = members
    end

    def paginate(which, options={})
      self
    end

    def total_pages
      1
    end

    def each(&blk)
      @members.each {|m| yield m}
    end

    def count
      @members.count
    end
  end

  def memberships
    memberships = members.map do |member|
      Membership.new(:user_id => member.id, :created_at => Time.now, :role => Role.member)
    end
    MembershipsWrapper.new(memberships)
  end

  # Load all Users who are members of this group
  # Nested groups are not supported, only entries with a [login_attribute]
  # value matching a User with the given username will be returned.
  def members
    configurator = self.class.ldap_configurator
    usernames = member_dns.map do |dn|
      self.class.user_dns_in_group(dn, configurator.members_attribute_name)
    end

    usernames.compact.flatten.map do |dn|
      username = dn.split(",").detect do |pair|
        k,v = pair.split("=")
        v if k == configurator.login_attribute
      end
      attr, username = dn.split(",").first.split("=")
      User.find_by_login(Gitorious::Authentication::LDAPConfigurator.transform_username(username))
    end.compact.uniq
  end

  def self.build_qualified_dn(user_spec)
    [user_spec, ldap_configurator.group_search_dn].compact.join(",")
  end

  def self.groups_for_user(user)
    ldap_group_names = ldap_group_names_for_user(user)
    return [] if ldap_group_names.blank?
    result = []
    all.each do |group|
      dns_in_group = group.member_dns.map {|dn| build_qualified_dn(dn)}
      ldap_group_names.map do |name|
        if dns_in_group.include?(name)
          result << group
        end
      end
    end

    result.compact
  end
end
