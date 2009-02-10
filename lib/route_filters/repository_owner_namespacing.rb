require "gitorious/reservations"
require 'routing_filter/base'

module RoutingFilter
  class RepositoryOwnerNamespacing < Base
    
    RESERVED_NAMES = Gitorious::Reservations::RESERVED_ROOT_NAMES
    CONTROLLER_NAMES = Gitorious::Reservations::CONTROLLER_NAMES + RESERVED_NAMES
    NAME_WITH_FORMAT_RE = /[a-z0-9_\-\.]+/i
    PREFIXES_TO_CONTROLLER = {
      "~" => "users",
      "+" => "teams",
      ""  => "projects",
    }
    PREFIXES_RE = Regexp.union(*PREFIXES_TO_CONTROLLER.keys)
    CONTROLLER_RE = Regexp.union(*PREFIXES_TO_CONTROLLER.invert.keys)
    
    def around_recognize(path, env, &block)
      if !reserved?(path)
         if path =~ /^\/(#{PREFIXES_RE})(#{NAME_WITH_FORMAT_RE})(\/.+)?/
           controller = PREFIXES_TO_CONTROLLER[$1]
           name = $2
           rest = $3
           if rest && !reserved_action_name?(name, controller) && !reserved?(rest, controller) && repository_scope?(rest)
             path.replace "/#{controller}/#{name}/repositories#{rest}".chomp("/")
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
        if result =~ /^\/(#{CONTROLLER_RE})\/(#{NAME_WITH_FORMAT_RE})\/repositories\/(#{NAME_WITH_FORMAT_RE})(.+)?/ && !reserved_action_name?($3, $1)
          result.replace "/#{PREFIXES_TO_CONTROLLER.invert[$1]}#{$2}/#{$3}#{$4}"
        elsif result =~ /^\/(#{CONTROLLER_RE})\/(#{NAME_WITH_FORMAT_RE})(.+)?/ && !reserved_action_name?($2, $1)
          result.replace "/#{PREFIXES_TO_CONTROLLER.invert[$1]}#{$2}#{$3}"
        end
      end
    end
    
    private
      def reserved?(path, controller = nil)
        (CONTROLLER_NAMES + reserved_actions_for_controller(controller)).select{|s| 
          path.starts_with?("/#{s}") 
        }.length != 0
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
        else
          []
        end
      end
      
      def repository_scope?(path)
        !Gitorious::Reservations::PROJECTS_MEMBER_ACTIONS.include?(path.sub("/", "")) && 
          path =~ /^\/(#{NAME_WITH_FORMAT_RE})(.+)?$/i
      end
  end
end