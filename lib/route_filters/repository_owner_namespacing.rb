# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
require "gitorious/reservations"
require 'routing_filter/base'

module RoutingFilter
  class RepositoryOwnerNamespacing < Base
    
    RESERVED_NAMES = Gitorious::Reservations.reserved_root_names
    CONTROLLER_NAMES = Gitorious::Reservations.controller_names + RESERVED_NAMES
    NAME_WITH_FORMAT_RE = /[a-z0-9_\-\.]+/i
    PREFIXES_TO_CONTROLLER = {
      "~" => "users",
      "+" => "teams",
      ""  => "projects",
    }
    PREFIXES_RE = Regexp.union(*PREFIXES_TO_CONTROLLER.keys)
    CONTROLLER_RE = Regexp.union(*PREFIXES_TO_CONTROLLER.invert.keys)
    
    # TODO: There's a special place in hell for this kinda logic; clean up
    
    def around_recognize(path, env, &block)
      if !reserved?(path)
         if path =~ /^\/(#{PREFIXES_RE})(#{NAME_WITH_FORMAT_RE})(\/.+)?/i
           controller = PREFIXES_TO_CONTROLLER[$1]
           name = $2
           rest = $3
           if rest && !reserved_action_name?(name, controller) && !reserved?(rest, controller) && repository_scope?(rest)
             # Handle repositories namespaced like ":user_or_team_id/:project_id/:repo_id"
             rest, project_or_repoish = rest.sub(/^\//, '').split("/", 2).reverse
             if !project_or_repoish.blank? && !rest.blank? && !reserved_action_name?(rest, "repositories") # got something that looks namespaced
               if reserved_action_name?(rest, controller) # we're looking for an action on repositories
                 path.replace "/#{controller}/#{name}/repositories/#{project_or_repoish}/#{rest}".chomp("/")
               else # We're in the /user_or_team/projectname/... scope
                 # We actually wanted another controller under repositories, not a repo:
                 if CONTROLLER_NAMES.include?(rest.split(".", 2).first.split("/")[0])
                   path.replace "/#{controller}/#{name}/repositories/#{project_or_repoish}/#{rest}".chomp("/")
                 else
                   path.replace "/#{controller}/#{name}/projects/#{project_or_repoish}/repositories/#{rest}".chomp("/")
                 end
               end
             else
               if project_or_repoish
                 path.replace "/#{controller}/#{name}/repositories/#{project_or_repoish}/#{rest}".chomp("/")
               else
                 path.replace "/#{controller}/#{name}/repositories/#{rest}".chomp("/")
               end
             end
           else
             path.replace "/#{controller}/#{name}#{rest}".chomp("/")
           end
         end
      end
      yield
      # returning yield(path, env) do |params|
      #   params
      # end
    end
    
    def around_generate(*args, &block)
      params = args.extract_options!
      returning yield do |result|
        result = result.is_a?(Array) ? result.first : result
        if result =~ /^\/(#{CONTROLLER_RE})\/(#{NAME_WITH_FORMAT_RE})\/repositories\/(#{NAME_WITH_FORMAT_RE})(.+)?/i && !reserved_action_name?($3, $1)
          result.replace "/#{PREFIXES_TO_CONTROLLER.invert[$1]}#{$2}/#{$3}#{$4}"
        elsif result =~ /^\/(#{CONTROLLER_RE})\/(#{NAME_WITH_FORMAT_RE})(.+)?/i && !reserved_action_name?($2, $1)
          controller, id, repo = [$1, $2, $3]
          if repo =~ /\/projects\/(#{NAME_WITH_FORMAT_RE})\/repositories\/(#{NAME_WITH_FORMAT_RE})(.+)?/i
            #result.replace "/#{PREFIXES_TO_CONTROLLER.invert[controller]}#{id}#{repo}"
            result.replace "/#{PREFIXES_TO_CONTROLLER.invert[controller]}#{id}/#{$1}/#{$2}#{$3}"
          else
            result.replace "/#{PREFIXES_TO_CONTROLLER.invert[controller]}#{id}#{repo}"
          end
        end
      end
    end
    
    private
      def reserved?(path, controller = nil)
        path_with_ending_slash = path.chomp("/") + "/" # Make sure we always only got one slash
        (CONTROLLER_NAMES + reserved_actions_for_controller(controller)).any? {|s| 
          path_with_ending_slash =~ /^\/#{s}(\..+)?\//
        }
      end
      
      def reserved_action_name?(name, controller)
        reserved_actions_for_controller(controller).include?(name)
      end
      
      def reserved_actions_for_controller(controller)
        case controller
        when "users"
          UsersController.action_methods.to_a
        when "projects"
          ProjectsController.action_methods.to_a
        when "groups", "teams"
          GroupsController.action_methods.to_a
        when "repositories"
          RepositoriesController.action_methods.to_a
        else
          []
        end
      end
      
      def repository_scope?(path)
        !Gitorious::Reservations.projects_member_actions.include?(path.sub("/", "")) && 
          path =~ /^\/(#{NAME_WITH_FORMAT_RE})(.+)?$/i
      end
  end
end
