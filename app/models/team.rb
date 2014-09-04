# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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
require "group_finder"
require "ldap_group_finder"

class Team
  def self.count
    group_finder.count
  end

  def self.group_implementation
    @group_implementation
  end

  def self.group_implementation=(klass)
    @group_implementation = klass
  end

  class Wrapper
    def initialize(group)
      @group = group
    end
  end

  class LdapGroupWrapper < Wrapper
    def events(page)
      []
    end

    def memberships
      if member_listing_enabled?
        @group.memberships
      end
    end

    private

    def member_listing_enabled?
      Gitorious::Configuration.get('enable_ldap_group_member_listing')
    end
  end

  class GroupWrapper < Wrapper
    def events(page)
      @group.events(page)
    end

    def memberships
      @group.memberships.includes(:user, :role)
    end
  end

  def self.group_wrapper(group)
    group.is_a?(LdapGroup) ? LdapGroupWrapper.new(group) : GroupWrapper.new(group)
  end

  # Return a (class level) finder
  def self.group_finder
    group_implementation == LdapGroup ? LdapGroupFinder.new : GroupFinder.new
  end

  def self.method_missing(name, *args, &block)
    if group_finder.respond_to?(name)
      group_finder.send(name, *args, &block)
    else
      super(name, *args, &block)
    end
  end

  def self.memberships(group)
    group_wrapper(group).memberships
  end

  def self.events(group, page)
    group_wrapper(group).events(page)
  end

  def self.create_group(params, user)
    group_finder.create_group(group_params(params), user)
  end

  def self.group_params(params)
    params.key?(:ldap_group) ? params[:ldap_group] : params[:group]
  end

  def self.update_group(group, params)
    params = group_params(params)
    group.description = params[:description]
    group.avatar = params[:avatar] if params[:avatar]
    group.ldap_group_names = params[:ldap_group_names] if params.key?(:ldap_group_names)
    group.save!
  end

  class DestroyGroupError < StandardError
  end

  def self.destroy_group(name, user)
    group = group_finder.find_by_name! name
    unless user.is_admin?
      raise DestroyGroupError, "You're not admin" unless group_admin?(group, user)
      raise DestroyGroupError, "Teams with current members or projects cannot be deleted" unless group.deletable?
    end
    group.destroy
  end

  def self.group_admin?(group, user)
    return false unless user
    role = group.user_role(user)
    role && role.admin?
  end

  def self.delete_avatar(group)
    group.avatar.destroy
    group.save
  end

  def self.can_have_members?(group)
    group.is_a?(Group)
  end
end
