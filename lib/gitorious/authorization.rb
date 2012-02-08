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
    ### Abilities
    def can_write_to?(user, repository)
      delegate(:can_write_to?, user, repository)
    end

    def can_delete?(candidate, repository)
      admin?(candidate, repository)
    end

    def can_resolve?(user, merge_request)
      delegate(:can_resolve?, user, merge_request)
    end

    def can_edit?(user, thing)
      return delegate(:can_edit_comment?, user, thing) if thing.is_a?(Comment)
    end

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

    private
    def delegate(method, *args)
      Configuration.strategies.each do |authorizor|
        if authorizor.respond_to?(method)
          result = authorizor.send(method, *args)
          return result if result
        end
      end
      nil
    end

    def delegate_with_default(method, default, *args)
      Configuration.strategies.each do |authorizor|
        if authorizor.respond_to?(method)
          return authorizor.send(method, *args)
        end
      end
      default
    end
  end
end
