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
module Gitorious
  module Authorization
    # Resolve authorization when "normal" group authorization is used
    #
    # The @authorizer instance variable is an object who is able to
    # perform authorization. This behavior is mixed into all
    # controllers, models etc. - and is able to do authorization which
    # is not handled by an LDAP authorization object; ie. direct user
    # access.
    class GroupAuthorization
      def initialize(authorizer)
        @authorizer = authorizer
      end

      def push_granted?(repository, user)
        @authorizer.committers(repository).include?(user)
      end

      def can_resolve_merge_request?(user, merge_request)
        return @authorizer.reviewers(merge_request.target_repository).include?(user)
      end

      def repository_admin?(candidate, repository)
        @authorizer.administrators(repository).include?(candidate)
      end
    end
  end
end
