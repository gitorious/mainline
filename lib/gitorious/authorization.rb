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
require "gitorious/authorization/configuration"

module Gitorious
  module Authorization
    class UnauthorizedError < StandardError; end

    def self.delegate_ability(action)
      self.send(:define_method, action) do |agent, subject|
        delegate(action, agent, subject)
      end
    end

    ### Abilities
    delegate_ability :can_read?
    delegate_ability :can_push?
    delegate_ability :can_delete?
    delegate_ability :can_edit?
    delegate_ability :can_request_merge?
    delegate_ability :can_resolve_merge_request?
    delegate_ability :can_reopen_merge_request?
    delegate_ability :can_grant_access?

    ### Roles
    def committer?(candidate, thing)
      if thing.is_a?(User)
        is_self = candidate == thing
        return delegate_with_default(:user_committer?, is_self, candidate, thing)
      end
      return delegate(:group_committer?, candidate, thing) if thing.is_a?(Group)
      delegate(:committer?, candidate, thing)
    end

    def reviewer?(user, repository)
      delegate(:reviewer?, user, repository)
    end

    def admin?(candidate, thing)
      delegate(:admin?, candidate, thing)
    end

    def site_admin?(user)
      delegate(:site_admin?, user)
    end

    def is_member?(agent, subject)
      delegate(:is_member?, agent, subject)
    end

    ### Data access
    def committers(repository)
      delegate_with_default(:committers, [], repository)
    end

    def reviewers(repository)
      delegate_with_default(:reviewers, [], repository)
    end

    def administrators(repository)
      delegate_with_default(:administrators, [], repository)
    end

    def review_repositories(user)
      delegate_with_default(:review_repositories, [], user)
    end

    def filter_authorized(actor, collection)
      delegate_with_default(:filter_authorized, [], actor, collection)
    end

    private
    def delegate(method, *args)
      Configuration.strategies.each do |authorizer|
        if authorizer.respond_to?(method)
          result = authorizer.send(method, *args)
          return result if result
        end
      end
      nil
    end

    def delegate_with_default(method, default, *args)
      Configuration.strategies.each do |authorizer|
        if authorizer.respond_to?(method)
          return authorizer.send(method, *args)
        end
      end
      default
    end
  end
end
