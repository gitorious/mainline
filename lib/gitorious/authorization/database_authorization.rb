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
require "gitorious/authorization/typed_authorization"
require "gitorious/authorization/group_authorization"
require "gitorious/authorization/ldap_group_authorization"
module Gitorious
  module Authorization
    class DatabaseAuthorization < Gitorious::Authorization::TypedAuthorization
      ### Abilities
      ability :can_read
      ability :can_edit
      ability :can_delete
      ability :can_grant_access

      # Load one of the group authorization types
      def select_group_authorization
        if Team.group_implementation ==  LdapGroup
          LdapGroupAuthorization.new(self)
        else
          GroupAuthorization.new(self)
        end
      end

      def can_read_project?(user, project)
        can_read_protected_content?(user, project)
      end

      def can_read_repository?(user, repository)
        if !repository.project.nil?
          return false if !can_read_protected_content?(user, repository.project)
        end
        can_read_protected_content?(user, repository)
      end

      def can_read_protected_content?(actor, subject)
        return true if !private_repos
        return true if site_admin?(actor)
        return true if subject.owner == actor
        return true if subject.content_memberships.count == 0
        subject.content_memberships.any? { |m| is_member?(actor, m.member) }
      end

      def can_read_group?(user, group)
        true
      end

      def can_read_merge_request?(user, mr)
        return true if !private_repos
        return true if site_admin?(user)
        (mr.project.nil? || can_read_project?(user, mr.project)) &&
          (mr.target_repository.nil? || can_read_repository?(user, mr.target_repository)) &&
          (mr.source_repository.nil? || can_read_repository?(user, mr.source_repository))
      end

      def can_read_merge_request_version?(user, version)
        return true if !private_repos
        can_read_merge_request?(user, version.merge_request)
      end

      def can_read_user?(actor, user)
        true
      end

      def can_read_event?(user, event)
        return true if !private_repos
        can_read_project?(user, event.project) && can_read?(user, event.target)
      end

      def can_read_favorite?(user, favorite)
        return true if !private_repos
        can_read_project?(user, favorite.project) && can_read?(user, favorite.watchable)
      end

      def can_read_message?(user, message)
        [message.sender, message.recipient].include?(user)
      end

      def can_read_comment?(user, comment)
        return true if !private_repos
        return true if site_admin?(user)
        (comment.project.nil? || can_read_project?(user, comment.project)) &&
          (comment.target.nil? || can_read?(user, comment.target))
      end

      # TODO: Needs more polymorphism
      def can_push?(user, repository)
        if repository.wiki?
          can_write_to_wiki?(user, repository)
        else
          push_granted?(repository, user)
        end
      end

      def push_granted?(repository, user)
        select_group_authorization.push_granted?(repository, user)
      end

      def can_delete_project?(candidate, project)
        admin?(candidate, project) && project.repositories.clones.count == 0
      end

      def can_delete_repository?(candidate, repository)
        admin?(candidate, repository)
      end

      def can_edit_comment?(user, comment)
        comment.creator?(user) && comment.recently_created?
      end

      def can_grant_access_project?(candidate, project)
        private_repos && admin?(candidate, project)
      end

      def can_request_merge?(user, repository)
        !repository.mainline? && can_push?(user, repository)
      end

      def can_resolve_merge_request?(user, merge_request)
        return false unless user.is_a?(User)
        return true if user === merge_request.user
        select_group_authorization.can_resolve_merge_request?(user, merge_request)
      end

      def can_reopen_merge_request?(user, merge_request)
        merge_request.can_reopen? && can_resolve_merge_request?(user, merge_request)
      end

      ### Roles

      def committer?(candidate, repository)
        candidate.is_a?(User) ? committers(repository).include?(candidate) : false
      end

      def reviewer?(candidate, repository)
        candidate.is_a?(User) ? reviewers(repository).include?(candidate) : false
      end

      def is_member?(candidate, thing)
        candidate == thing || (thing.respond_to?(:member?) && thing.member?(candidate))
      end

      ###

      def repository_admin?(candidate, repository)
        return false if !candidate.is_a?(User)
        return true if candidate == repository.owner
        select_group_authorization.repository_admin?(candidate, repository)
      end

      def project_admin?(candidate, project)
        if Team.group_implementation == LdapGroup
          return select_group_authorization.project_admin?(candidate, project)
        else
          return admin?(candidate, project.owner)
        end
      end

      def group_admin?(candidate, group)
        group.user_role(candidate) == Role.admin
      end

      def group_committer?(candidate, group)
        [Role.admin, Role.member].include?(group.user_role(candidate))
      end

      def site_admin?(user)
        user.is_a?(User) && user.is_admin
      end

      # returns an array of users who have commit bits to this repository either
      # directly through the owner, or "indirectly" through the associated
      # groups
      def committers(repository)
        repository.committerships.committers.map{|c| c.members }.flatten.compact.uniq
      end

      # Returns a list of Users who can review things (as per their Committership)
      def reviewers(repository)
        repository.committerships.reviewers.map{|c| c.members }.flatten.compact.uniq
      end

      # The list of users who can admin this repo, either directly as
      # committerships or indirectly as members of a group
      def administrators(repository)
        repository.committerships.admins.map{|c| c.members }.flatten.compact.uniq
      end

      def review_repositories(user)
        user.committerships.reviewers
      end

      def filter_authorized(actor, collection)
        return collection if !private_repos
        return [] if collection.blank?
        collection.select { |item| can_read?(actor, item) }
      end

      private
      def can_write_to_wiki?(user, repository)
        case repository.wiki_permissions
        when Repository::WIKI_WRITABLE_EVERYONE
          return true
        when Repository::WIKI_WRITABLE_PROJECT_MEMBERS
          return repository.project.member?(user)
        end
      end

      def private_repos
        GitoriousConfig["enable_private_repositories"]
      end
    end
  end
end
